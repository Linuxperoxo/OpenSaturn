// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: spea.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").interfaces.arch;
const allocator: type = @import("root").interfaces.allocator;
const ar: type = @import("root").ar;

const Allocator_T: type = allocator.Allocator_T;
const VTable_T: type = allocator.VTable_T;
const Err_T: type = allocator.Err_T;
const InternalErr_T: type = error {
    PoolIsFull,
    PoolInitFailed,
    PoolNotInitialized,
    PoolDeinitFailed,
    MemoryFragmentation,
    InvalidAllocation,
    InvalidSize,
};

// === Saturn Pool Expandable Allocator ===

pub fn buildByteAllocator(
    comptime block: ?comptime_int,
) type {
    comptime if(ar.target_code.allocators == null or ar.target_code.allocators.spea == null)
        @compileError("target \"" ++ @tagName(ar.target_code.target) ++ "\" does not support the spea allocator");

    return struct {
        const pool_block_size: usize = block orelse 32;
        const pool_bitmap_len: usize = ar.target_code.allocators.spea.?.page;

        const BitMapVec_T: type = @Vector(pool_bitmap_len, u1);
        const BitMapInt_T: type = @Type(.{ .int = .{ .bits = pool_bitmap_len, .signedness = .unsigned } });

        const PoolInfo_T: type = struct {
            pool: ?[]u8          = null,
            next: ?*PoolInfo_T   = null,
            prev: ?*PoolInfo_T   = null,
            private: ?*anyopaque = null,

            // 1 -> busy block
            // 0 -> free block
            bitmap: BitMapVec_T = @splat(0),

            inline fn init(self: *PoolInfo_T) InternalErr_T!void {
                if(self.pool != null)
                    return;

                const arch_ctx = ar.target_code.allocators.spea.?.alloc_fn() catch
                    return InternalErr_T.PoolInitFailed;

                self.*       = .{};
                self.pool    = arch_ctx.ptr;
                self.private = arch_ctx.private;
                self.bitmap  |= @as(BitMapInt_T, @bitCast(~self.bitmap)) >> comptime (pool_bitmap_len - bytes_to_block(@sizeOf(PoolInfo_T)));
            }

            inline fn deinit(self: *PoolInfo_T) InternalErr_T!void {
                ar.target_code.allocators.spea.?.free_fn(self.private.?) catch
                    InternalErr_T.PoolDeinitFailed;
            }

            inline fn create_child(self: *PoolInfo_T) *PoolInfo_T {
                self.next = @alignCast(@ptrCast(self.pool.?.ptr));

                return self.next.?;
            }

            /// Checks if the allocation belongs to the pool
            inline fn valid_allocation(self: *const PoolInfo_T, allocation: []u8) bool {
                const pool_addrs: usize  = @intFromPtr(self.pool.?.ptr);
                const alloc_addrs: usize = @intFromPtr(allocation.ptr);

                if((allocation.len == 0) or
                    (alloc_addrs < pool_addrs) or
                    ((alloc_addrs - pool_addrs) % pool_block_size != 0))
                    return false;

                return ((alloc_addrs - pool_addrs) + allocation.len) <= self.pool.?.len;
            }

            /// Generates a mask with blocks_sequence consecutive bits set to 1
            inline fn bitmap_sequence_mask(blocks_sequence: usize) BitMapInt_T {
                const mask: BitMapInt_T = 0;
                const shift: usize = pool_bitmap_len - blocks_sequence;

                return (~mask) >> shift;
            }

            /// Checks if the pool is full using bitwise expression
            inline fn is_full(self: *const PoolInfo_T) bool {
                const bitmap: BitMapInt_T = @bitCast(self.bitmap);

                return (~bitmap) == 0;
            }

            /// Returns the number of blocks needed to hold bytes rounded up
            inline fn bytes_to_block(bytes: usize) usize {
                return (bytes + pool_block_size - 1) / pool_block_size;
            }

            pub fn alloc(self: *PoolInfo_T, bytes: usize) InternalErr_T![]u8 {
                if(bytes == 0)     return InternalErr_T.InvalidAllocationSize;
                if(self.is_full()) return InternalErr_T.PoolIsFull;

                const sequence_mask: BitMapInt_T = bitmap_sequence_mask(bytes_to_block(bytes));

                var bitmap: BitMapInt_T  = ~@as(BitMapInt_T, @bitCast(self.bitmap));
                var ctz: usize           = @ctz(bitmap);
                var initial_block: usize = ctz;

                bitmap >>= ctz;

                r: {
                    while(bitmap != 0) {
                        if((bitmap & sequence_mask) == sequence_mask)
                            break :r {};

                        ctz = @ctz(~bitmap);

                        bitmap >>= ctz;
                        initial_block += ctz;

                        ctz = @ctz(bitmap);

                        bitmap >>= ctz;
                        initial_block += ctz;
                    }
                    return InternalErr_T.MemoryFragmentation;
                }

                const initial_pool_index: usize = initial_block * pool_block_size;
                const final_pool_index: usize   = initial_pool_index + bytes;

                self.bitmap |= @as(BitMapVec_T, @bitCast(sequence_mask << initial_block));

                return self.pool.?[initial_pool_index..final_pool_index];
            }

            pub fn free(self: *PoolInfo_T, allocation: []u8) InternalErr_T!void {
                if(!self.valid_allocation(allocation))
                    return InternalErr_T.InvalidAllocation;

                const initial_block: usize       = (@intFromPtr(allocation.ptr) - @intFromPtr(self.pool.?.ptr)) / pool_block_size;
                const sequence_mask: BitMapInt_T = bitmap_sequence_mask(bytes_to_block(allocation.len));

                self.bitmap &= ~@as(BitMapVec_T, @bitCast(sequence_mask << initial_block));
            }
        };

        root_pool: PoolInfo_T,
        blocks: usize,
        pools: usize,
        last: *PoolInfo_T,

        pub noinline fn init(self: *@This()) Err_T!void {
            self.root_pool.init() catch return Err_T.InitFailed;
            self.last = &self.root_pool;
        }

        pub noinline fn deinit(self: *@This()) Err_T!void {
            var current_pool: ?*PoolInfo_T = self.last;

            while(current_pool != null) {
                const prev: ?*PoolInfo_T = current_pool.?.prev;

                current_pool.?.deinit()
                    catch return Err_T.InternalError;

                current_pool = prev;
            }
        }

        pub noinline fn alloc(self: *@This(), N: usize) Err_T![]u8 {
            var current_pool: *PoolInfo_T = &self.root_pool;

            while(true) {
                const allocation = current_pool.alloc(N) catch |err| {
                    @branchHint(.unlikely);
                    sw: switch(err) {
                        InternalErr_T.MemoryFragmentation, InternalErr_T.PoolIsFull => {
                            @branchHint(.likely);

                            const new_pool: *PoolInfo_T = current_pool.create_child();

                            new_pool.init() catch |init_err|
                                continue :sw init_err;

                            new_pool.prev = current_pool;

                            current_pool = new_pool;

                            self.last = new_pool;

                            continue;
                        },

                        else => return Err_T.InternalError,
                    }
                };
                return allocation;
            }
        }

        pub noinline fn free(self: *@This(), ptr: []u8) void {
            var current_pool: ?*PoolInfo_T = &self.root_pool;

            while(current_pool != null) {
                current_pool.?.free(ptr) catch {
                    @branchHint(.cold);
                    current_pool = current_pool.?.next;
                };
            }
        }

        pub inline fn allocator(self: *const @This()) Allocator_T {
            const This_T: type = @This();
            const caller_handler: type = opaque {
                pub inline fn opaque_init(opaque_self: *anyopaque) Err_T!void {
                    const casted_self: *This_T = @ptrCast(@alignCast(opaque_self));
                    return casted_self.init();
                }

                pub inline fn opaque_deinit(opaque_self: *anyopaque) Err_T!void {
                    const casted_self: *This_T = @ptrCast(@alignCast(opaque_self));
                    return casted_self.deinit();
                }

                pub inline fn opaque_alloc(opaque_self: *anyopaque, N: usize) Err_T![]u8 {
                    const casted_self: *This_T = @ptrCast(@alignCast(opaque_self));
                    return casted_self.alloc(N);
                }

                pub inline fn opaque_free(opaque_self: *anyopaque, ptr: []u8) void {
                    const casted_self: *This_T = @ptrCast(@alignCast(opaque_self));
                    return casted_self.free(ptr);
                }
            };

            return Allocator_T{
                .vtable = &VTable_T{
                    .init = &caller_handler.opaque_init,
                    .deinit = &caller_handler.opaque_deinit,
                    .alloc = &caller_handler.opaque_alloc,
                    .free = &caller_handler.opaque_free,
                },
                .private = self,
            };
        }
    };
}
