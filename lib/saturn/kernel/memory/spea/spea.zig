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
const InternalErr_T: type = error{ PoolIsFull, PoolInitFailed, PoolNotInitialized, PoolDeinitFailed, MemoryFragmentation };

// === Saturn Pool Expandable Allocator ===

pub fn buildByteAllocator(
    comptime block: ?comptime_int,
) type {
    comptime if(ar.target_code.arch.allocators == null or ar.target_code.arch.allocators.spea == null)
        @compileError("target \"" ++ @tagName(ar.target_code.target) ++ "\" does not support the spea allocator");

    const target_code_spea: arch.ArchDescription_T.Allocator_T = ar.target_code.arch.allocators.spea;

    return struct {
        const pool_block_size: usize = block orelse 32;
        const pool_bitmap_len: usize = target_code_spea.page;

        const BitMapInt_T: type = @Type(.{ .int = .{ .bits = pool_bitmap_len, .signedness = .unsigned } });

        const PoolInfo_T: type = struct {
            pool: ?[]u8 = null,
            next: ?*PoolInfo_T = null,
            prev: ?*PoolInfo_T = null,
            private: ?*anyopaque = null,
            child: ?*PoolInfo_T = null,

            // 1 -> busy block
            // 0 -> free block
            bitmap: @Vector(pool_bitmap_len, u1) = @splat(0),

            fn init(self: *PoolInfo_T) void {

            }

            fn create_child(self: *PoolInfo_T) *PoolInfo_T {
                self.child = if(self.child == null) @alignCast(@ptrCast(&self.pool.?[0]))
                    else self.child;

                return self.child.?;
            }

            /// Generates a mask with blocks_sequence consecutive bits set to 1
            fn bitmap_sequence_mask(blocks_sequence: usize) BitMapInt_T {
                const mask: BitMapInt_T = 0;
                const shift: usize = pool_bitmap_len - blocks_sequence;

                return (~mask) >> shift;
            }

            fn is_full(self: *const PoolInfo_T) bool {
                const bitmap: BitMapInt_T = @bitCast(self.bitmap);

                return (~bitmap) == 0;
            }

            /// Returns the number of blocks needed to hold bytes rounded up
            fn bytes_to_block(bytes: usize) usize {
                return (pool_block_size + bytes - 1) / pool_block_size;
            }

            pub fn alloc(self: *PoolInfo_T, bytes: usize) InternalErr_T![]u8 {
                if(self.is_full())
                    return InternalErr_T.PoolIsFull;

                const sequence_mask: BitMapInt_T = bitmap_sequence_mask(bytes_to_block(bytes));

                var bitmap: BitMapInt_T = ~@as(BitMapInt_T, @bitCast(self.bitmap));
                var ctz: usize = @ctz(bitmap);
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
                }


            }

            pub fn free(self: *PoolInfo_T, allocation: []u8) InternalErr_T!void {

            }
        };

        root_pool: PoolInfo_T,
        blocks: usize,
        pools: usize,

        pub noinline fn init(self: *@This()) Err_T!void {
            if (self.root_pool.is_initialized())
                return;

            self.root_pool.init_pool() catch return Err_T.InitFailed;
        }

        pub noinline fn deinit(self: *@This()) Err_T!void {}

        pub noinline fn alloc(self: *@This(), N: usize) Err_T![]u8 {
        
        }

        pub noinline fn free(self: *@This(), ptr: []u8) void {

        }

        pub noinline fn resize(self: *@This(), ptr: []u8, N: usize) Err_T![]u8 {}

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

                pub inline fn opaque_resize(opaque_self: *anyopaque, ptr: []u8, N: usize) Err_T![]u8 {
                    const casted_self: *This_T = @ptrCast(@alignCast(opaque_self));
                    return casted_self.resize(ptr, N);
                }
            };

            return Allocator_T{
                .vtable = &VTable_T{
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
