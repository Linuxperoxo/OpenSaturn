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
const InternalErr_T: type = error{ PoolIsFull, PoolInitFailed, PoolNotInitialized, PoolDeinitFailed, MemoryFragmentation };

// === Saturn Pool Expandable Allocator ===

pub inline fn arch_pool_len() usize {
    return switch (comptime ar.target_code.target) {
        .i386 => 4096,
        else => @compileError(""),
    };
}

pub inline fn arch_pool_init() struct { *anyopaque, []u8 }!anyerror {
    switch (comptime ar.target_code.target) {
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
    switch (comptime ar.target_code.target) {
        .i386 => {
            return mm.free_page(private orelse return);
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

        const BitMapInt_T: type = @Type(.{ .int = .{ .bits = pool_bitmap_len, .signedness = .unsigned } });

        const PoolInfo_T: type = struct {
            pool: ?[]u8 = null,
            next: ?*PoolInfo_T = null,
            prev: ?*PoolInfo_T = null,
            private: ?*anyopaque = null,

            bitmap: @Vector(pool_bitmap_len, u1) = @splat(0),
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
            var current_pool: ?*PoolInfo_T = &self.root_pool;

            while (current_pool) |pool| {
                const allocation: []u8 = pool.alloc_blocks(N) catch |err| {
                    @branchHint(.unlikely);
                    sw: switch (err) {
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

        pub noinline fn free(self: *@This(), ptr: []u8) void {}

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
