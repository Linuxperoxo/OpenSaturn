// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: sba.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const allocator: type = @import("root").interfaces.allocator;

const Allocator_T: type = allocator.Allocator_T;
const Vtable_T: type = allocator.Vtable_T;

// === Saturn Byte Allocator ===

pub fn buildByteAllocator(
    comptime block: ?comptime_int,
    comptime pool_size: ?comptime_int,
    comptime resized: bool
) type {
    return struct {
        const pool_bitmap_len: usize = pool_size orelse 2048;

        const AllocatorInfo_T: type = struct {
            root_pool: ?*PoolInfo_T,
            blocks: usize,
            pools: usize,
        };

        const PoolInfo_T: type = struct {
            pool: []u8,
            next: ?*PoolInfo_T,
            prev: ?*PoolInfo_T,
            bitmap: @Vector(pool_bitmap_len, u1),
            private: *anyopaque,

            pub inline fn is_full(self: *const PoolInfo_T) bool {
                const casted_vector: @Type(.{
                    .int = .{
                        .bits = pool_bitmap_len,
                        .signedness = .unsigned
                    }
                }) = @bitCast(self.bitmap);
                return ~casted_vector == 0;
            }
        };

        const Err_T: type = error {

        };

        info: *anyopaque,

        pub noinline fn alloc(self: *@This(), N: usize) Err_T![]u8 {
            
        }

        pub noinline fn free(self: *@This(), ptr: []u8) void {

        }

        pub noinline fn resize(self: *@This(), ptr: []u8, N: usize) Err_T![]u8 {

        }

        pub inline fn allocator(self: *const @This()) Allocator_T {
            return Allocator_T {
                .vtable = &Vtable_T {
                    .alloc = &alloc,
                    .free = &free,
                    .resize = &resize,
                },
            };
        }
    };
}
