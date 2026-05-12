// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: spea.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const allocator: type = @import("root").interfaces.allocator;
const ar: type = @import("root").ar;
const mm: type = @import("root").ar.target_code.mm;

const Allocator_T: type = allocator.Allocator_T;
const VTable_T: type = allocator.VTable_T;
const Err_T: type = allocator.Err_T;
const InternalErr_T: type = error {
    PoolIsFull,
    PoolInitFailed,
    PoolNotInitialized,
    PoolDeinitFailed,
    MemoryFragmentation
};

// === Saturn Pool Expandable Allocator ===

pub inline fn arch_pool_len() usize {
    return switch(comptime ar.target_code.target) {
        .i386 => 4096,
        else => @compileError(""),
    };
}

pub inline fn arch_pool_init() struct { *anyopaque, []u8 }!anyerror {
    switch(comptime ar.target_code.target) {
        .i386 => {
            const page: mm.AllocPage_T = try mm.alloc_page();
            return .{
                page,
                page.virtual,
            };
        },

        else => @compileError(""),
    }
}

pub inline fn arch_pool_deinit(private: ?*anyopaque) anyerror!void {
    switch(comptime ar.target_code.target) {
        .i386 => {
            return mm.free_page(
                private orelse return
            );
        },

        else => @compileError(""),
    }
}

pub fn buildByteAllocator(
    comptime block: ?comptime_int,
) type {
    return struct {
        const pool_block_size: usize = block orelse 32;
        const pool_bitmap_len: usize = arch_pool_len();

        const BitMapInt_T: type = @Type(.{
            .int = .{
                .bits = pool_bitmap_len,
                .signedness = .unsigned
            }
        });

        const PoolInfo_T: type = struct {
            pool: ?[]u8          = null,
            next: ?*PoolInfo_T   = null,
            prev: ?*PoolInfo_T   = null,
            private: ?*anyopaque = null,

            bitmap: @Vector(pool_bitmap_len, u1) = @splat(0),

            inline fn cast_bitmap(self: *const PoolInfo_T) BitMapInt_T {
                return @bitCast(self.bitmap);
            }

            inline fn find_blocks_index(self: *const PoolInfo_T, sequence: usize) InternalErr_T!usize {
                // one free block is guaranteed
                const bitmap_expect_sequence: BitMapInt_T = (~@as(BitMapInt_T, 0)) >> (pool_bitmap_len - sequence);

                var bitmap: BitMapInt_T = ~@as(BitMapInt_T, @bitCast(self.bitmap));
                var bitmap_ctz: usize = @ctz(bitmap);
                var initial_index_free: usize = bitmap_ctz;

                bitmap >>= @intCast(bitmap_ctz);

                while(bitmap != 0) {
                    if((bitmap & bitmap_expect_sequence) == bitmap_expect_sequence)
                        return initial_index_free;

                    bitmap_ctz = @ctz(bitmap) + 1;

                    bitmap >>= @intCast(bitmap_ctz);
                    initial_index_free += bitmap_ctz;
                }
                return InternalErr_T.MemoryFragmentation;
            }

            inline fn reserve_child(self: *PoolInfo_T) void {
                self.bitmap = @as(BitMapInt_T, self.bitmap) | (~@Type(.{
                    .int = .{
                        .bits = ((@sizeOf(@This()) + pool_block_size - 1) / pool_block_size),
                        .signedness = .unsigned,
                    },
                }));
            }

            inline fn reset(self: *PoolInfo_T) void {
                self = .{};
            }

            inline fn is_full(self: *const PoolInfo_T) bool {
                const casted_vector: BitMapInt_T = @bitCast(self.bitmap);
                return ~casted_vector == 0;
            }

            pub inline fn valid_allocation(self: *const PoolInfo_T, ptr: []u8) bool {
                if(self.pool == null)
                    return false;

                const supposed_addrs: usize = @intFromPtr(ptr.ptr);
                const target_addrs: usize = @intFromPtr(self.pool.?);

                const validation = [_]bool {
                    (supposed_addrs >= target_addrs),
                    ((supposed_addrs + ptr.len) <= (target_addrs + self.pool.?.len)),
                };

                return @reduce(.And, @as(@Vector(3, bool), @bitCast(validation)));
            }

            pub inline fn is_initialized(self: *const PoolInfo_T) bool {
                return (self.pool != null and self.private != null);
            }

            pub inline fn init_pool(self: *PoolInfo_T) InternalErr_T!void {
                if(self.is_initialized())
                    return;

                self.reset();

                self.private, self.pool = arch_pool_init()
                    catch return InternalErr_T.PoolInitFailed;

                self.reserve_child();
            }

            pub inline fn deinit_pool(self: *PoolInfo_T) InternalErr_T!void {
                if(!self.is_initialized())
                    return;

                arch_pool_deinit(self.private)
                    catch return InternalErr_T.PoolDeinitFailed;

                self.reset();
            }

            pub inline fn alloc_blocks(self: *PoolInfo_T, N: usize) InternalErr_T![]u8 {
                if(!self.is_initialized()) return InternalErr_T.PoolNotInitialized;
                if(self.is_full()) return InternalErr_T.PoolIsFull;

                const blocks_sequence: usize = (N + pool_block_size - 1) / pool_block_size;
                const initial_block: usize = self.find_blocks_index(blocks_sequence);
                const mask: BitMapInt_T = ((~@as(BitMapInt_T, 0)) >> (pool_bitmap_len - blocks_sequence) << initial_block);

                self.bitmap = @as(BitMapInt_T, @bitCast(self.bitmap)) | mask;

                const initial_pool_index: usize = initial_block * pool_block_size;
                const final_pool_index: usize = initial_block + (blocks_sequence * pool_block_size);

                return self.pool[initial_pool_index..final_pool_index];
            }

            pub inline fn create_child(self: *PoolInfo_T) *PoolInfo_T {
                self.next = @alignCast(@ptrCast(&self.pool[0]));
                return self.next;
            }
        };

        root_pool: PoolInfo_T,
        blocks: usize,
        pools: usize,

        pub noinline fn init(self: *@This()) Err_T!void {
            if(self.root_pool.is_initialized())
                return;

            self.root_pool.init_pool()
                catch return Err_T.InitFailed;
        }

        pub noinline fn deinit(self: *@This()) Err_T!void {
            
        }

        pub noinline fn alloc(self: *@This(), N: usize) Err_T![]u8 {
            var current_pool: ?*PoolInfo_T = &self.root_pool;

            while(current_pool) |pool| {
                const allocation: []u8 = pool.alloc_blocks(N) catch |err| {
                    @branchHint(.unlikely);
                    sw: switch(err) {
                        InternalErr_T.PoolNotInitialized => {
                            @branchHint(.unlikely);
                            current_pool.?.init_pool() catch return Err_T.InternalError;
                            continue;
                        },

                        InternalErr_T.PoolIsFull => {
                            @branchHint(.likely);
                            current_pool = pool.create_child();
                            continue :sw InternalErr_T.PoolNotInitialized;
                        },

                        else => unreachable,
                    }
                };
                return allocation;
            }
            unreachable;
        }

        pub noinline fn free(self: *@This(), ptr: []u8) void {
            
        }

        pub noinline fn resize(self: *@This(), ptr: []u8, N: usize) Err_T![]u8 {
            
        }

        pub inline fn allocator(self: *const @This()) Allocator_T {
            const This_T: type = @This();
            const caller_handler: type = opaque {
                pub inline fn opaque_init(opaque_self: *anyopaque) Err_T!void {
                    const casted_self: *This_T = @alignCast(@ptrCast(opaque_self));
                    return casted_self.init();
                }

                pub inline fn opaque_deinit(opaque_self: *anyopaque) Err_T!void {
                    const casted_self: *This_T = @alignCast(@ptrCast(opaque_self));
                    return casted_self.deinit();
                }

                pub inline fn opaque_alloc(opaque_self: *anyopaque, N: usize) Err_T![]u8 {
                    const casted_self: *This_T = @alignCast(@ptrCast(opaque_self));
                    return casted_self.alloc(N);
                }

                pub inline fn opaque_free(opaque_self: *anyopaque, ptr: []u8) void {
                    const casted_self: *This_T = @alignCast(@ptrCast(opaque_self));
                    return casted_self.free(ptr);
                }

                pub inline fn opaque_resize(opaque_self: *anyopaque, ptr: []u8, N: usize) Err_T![]u8 {
                    const casted_self: *This_T = @alignCast(@ptrCast(opaque_self));
                    return casted_self.resize(ptr, N);
                }
            };

            return Allocator_T {
                .vtable = &VTable_T {
                    .init = &caller_handler.opaque_init,
                    .deinit = &caller_handler.opaque_deinit,
                    .alloc = &caller_handler.opaque_alloc,
                    .free = &caller_handler.opaque_free,
                    .resize = &caller_handler.opaque_resize,
                },
                .private = self,
            };
        }
    };
}
