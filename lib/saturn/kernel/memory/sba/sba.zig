// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: sba.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const ar: type = @import("root").ar;
const builtin: type = @import("builtin");
const mm: type = @import("root").code.mm;
const types: type = @import("types.zig");
const config: type = @import("root").config;
const std: type = @import("std");
const vtable: type = if(!builtin.is_test) @import("root").lib.memory.vtable else struct {
    pub const AllocVTable_T: type = struct {
        fn_alloc: *const fn(self: *const @This(), bytes: usize) anyerror![]u8,
        fn_free: *const fn(self: *const @This(), ptr: []u8) anyerror!void,
        private: *anyopaque,

        pub fn alloc(self: *const @This(), comptime T: type, N: usize) anyerror![]T {
            return @alignCast(@ptrCast(
                (try self.fn_alloc(self, @sizeOf(T) * N))
            ));
        }

        pub fn free(self: *const @This(), ptr: anytype) anyerror!void {
            return self.fn_free(self, comptime sw: switch(@typeInfo(@TypeOf(ptr))) {
                .pointer => |p| {
                    if(p.size == .c or p.size == .many)
                        continue :sw @typeInfo(void);
                    break :sw @alignCast(@ptrCast(ptr[0..if(p.size == .one) 1 else ptr.len]));
                },

                else => @compileError("expect slice or single pointer to free. Found \"" ++ @typeName(@TypeOf(ptr)) ++ "\""),
            });
        }
    };
};

// === Saturn Byte Allocator ===

const total_bytes_of_pool_test: comptime_int = 4096;
const default_block_size: comptime_int = 16;
const total_bytes_of_pool = if(builtin.is_test) total_bytes_of_pool_test else switch(config.arch.options.Target) {
    .i386 => config.kernel.options.kernel_page_size,
    else => unreachable,
};

pub fn buildByteAllocator(
    comptime block: ?comptime_int,
    comptime options: types.Options_T,
) type {
    return struct {
        pub const Debug_T: type = if(options.debug) struct {
            allocs: usize = 0,
            pools: usize = 0,
            bytes: usize = 0,
            bmarks: usize = 0,
        } else void;

        const block_size: comptime_int = block orelse default_block_size;
        const vector_blocks: comptime_int = ((total_bytes_of_pool + block_size) / block_size);

        const BitmapInt_T: type = @Type(.{
            .int = .{
                .bits = vector_blocks,
                .signedness = .unsigned,
            },
        });

        pub const Pool_T: type = struct {
            pool: ?*[total_bytes_of_pool]u8 = null,
            prev: ?*Pool_T = null,
            bitmap: @Vector(vector_blocks, u1) = @splat(1),
            private: *anyopaque,
            flags: packed struct {
                child: u1 = 0,
                full: u1 = 0,
            } = .{},

            pub fn child(self: *@This()) ?*Pool_T {
                return if(self.pool == null) null else
                    @alignCast(@ptrCast(&self.pool.?[0]));
            }

            pub fn init(self: *@This()) anyerror!void {
                self.* = .{};
                self.pool = sw: switch(comptime ar.target_code.target) {
                    .i386 => {
                        const page = try mm.alloc_page();
                        self.private = page;
                        break :sw @alignCast(@ptrCast(page.virtual.ptr));
                    },
                    else => unreachable,
                };
                if(comptime options.resize) {
                    // deixa blocos reservados para expandir o alocador
                    // quando esse pool estiver cheio
                    const initial_block_index: usize = 0;
                    const total_blocks: usize = (block_size + @sizeOf(Pool_T)) / block_size;
                    for(initial_block_index..total_blocks) |i|
                        self.bitmap[i] = 0;
                }
            }

            pub fn deinit(self: *@This()) anyerror!void {
                const private: *anyopaque = self.private;
                if(comptime options.resize) {
                    if(self.flags.child == 1) {
                        // caso o pool atual tenha um filho
                        @as(*Pool_T, @alignCast(@ptrCast(
                            // * caso tenha um pai, passamos o filhos do pool
                            // atual para seu pai
                            // * caso nao tenha um pai, substituimos o pool
                            // atual pelo seu filho
                            if(self.prev != null) &self.prev.?.pool.?[0] else self
                        ))).* = self.child().?.*;
                    } else {
                        // caso tenha um pai, invalidamos esse pool como filho
                        if(self.prev != null) self.prev.?.flags.child = 0;
                    }
                }
                switch(comptime ar.target_code.target) {
                    .i386 => try mm.free_page(@alignCast(@ptrCast(private))),
                    else => unreachable,
                }
                self.pool = null;
            }

            pub fn alloc(self: *@This(), bytes: usize) Err_T![]u8 {
                if(self.pool == null) return Err_T.NoNInitialized;
                if(self.flags.full == 1) return Err_T.WithOutBlocks;

                var free_blocks: BitmapInt_T = @bitCast(self.bitmap);

                const pop_count = @popCount(free_blocks);
                if(pop_count == 0 or (pop_count * block_size) < bytes) {
                    self.flags.full = 1;
                    return Err_T.WithOutBlocks;
                }

                const total_blocks: usize = (block_size + bytes) / block_size;
                var initial_block_index: usize = 0;
                var bit_sequence: usize = 0;
                for(0..total_blocks) |_| {
                    bit_sequence <<= 1;
                    bit_sequence |= 1;
                }
                r: {
                    while(free_blocks != 0) {
                        initial_block_index = @ctz(free_blocks);
                        free_blocks >>= initial_block_index;

                        if(@popCount(free_blocks & bit_sequence) == total_blocks)
                            break :r {};
                    }
                }

                for(0..total_blocks) |i|
                    self.bitmap[initial_block_index + i] = 0;
                self.flags.full = @intFromBool((free_blocks >> total_blocks) == 0);

                return self.pool.?[
                    initial_block_index * block_size
                    ..
                    ((initial_block_index * block_size) + bytes)
                ];
            }

            pub fn free(self: *@This(), ptr: []u8) Err_T!void {
                if(self.pool == null) return Err_T.NoNInitialized;
                if(((@intFromPtr(ptr) - self.pool.?) + ptr.len) >= total_bytes_of_pool) return Err_T.IndexOutBounds;

                const initial_block_index: usize = (@intFromPtr(ptr) - self.pool.?) / block_size;
                const total_blocks: usize = (block_size + ptr.len) / block_size;

                for(0..total_blocks) |i|
                    self.bitmap[initial_block_index + i] = 1;
                self.flags.full = 0;
            }
        };

        pub const Err_T: type = error {
            AlreadyInitialized,
            IndexOutBounds,
            NoNInitialized,
            WithOutMemory,
            ResizeFailed,
        };

        root: Pool_T,
        err: ?Err_T,
        debug: Debug_T,

        fn init(self_vtable: *const vtable.AllocVTable_T) Err_T!void {
            const self: *@This() = @alignCast(@ptrCast(self_vtable.private));
            try self.root.init();
        }

        fn deinit(self_vtable: *const vtable.AllocVTable_T) void {
            const self: *@This() = @alignCast(@ptrCast(self_vtable.private));
            try self.root.deinit();
        }

        fn alloc(self_vtable: *const vtable.AllocVTable_T, bytes: usize) Err_T![]u8 {
            const self: *@This() = @alignCast(@ptrCast(self_vtable.private));
            sw: switch((enum { alloc }).alloc) {
                .alloc => {
                    var current_pool: *Pool_T = &self.root;
                    while(current_pool.alloc(bytes)) |allocation| {
                        // DEBUG
                        if(comptime options.debug) {
                            self.debug.allocs += 1;
                            self.debug.bytes += bytes;
                            self.debug.bmarks += (block_size + bytes) / block_size;
                        }
                        return allocation;
                    } else |err| switch(err) {
                        Err_T.NoNInitialized => return err,
                        Err_T.WithOutMemory => {
                            if(comptime !options.resize) return err;
                            const child: *Pool_T = current_pool.child().?;
                            if(current_pool.flags.child == 0) {
                                child.init() catch return Err_T.ResizeFailed;
                                child.prev = current_pool;
                                current_pool.flags.child = 1;
                                // DEBUG
                                if(comptime options.debug)
                                    self.debug.pools += 1;
                            }
                            current_pool = child;
                            continue :sw .alloc;
                        },
                        else => unreachable,
                    }
                },
            }
        }

        fn free(self_vtable: *const vtable.AllocVTable_T, ptr: []u8) Err_T!void {
            const self: *@This() = @alignCast(@ptrCast(self_vtable.private));
            sw: switch((enum { free }).free) {
                .free => {
                    var current_pool: *Pool_T = &self.root;
                    while(current_pool.free(ptr)) |_| {
                        if(~@as(BitmapInt_T, @bitCast(current_pool.bitmap)) == 1)
                            current_pool.deinit();
                        // DEBUG
                        if(comptime options.debug) {
                            self.debug.allocs += 1;
                            self.debug.bytes += ptr.len;
                            self.debug.bmarks += (block_size + ptr.len) / block_size;
                        }
                        return;
                    } else |err| {
                        if(comptime !options.resize) return err;
                        current_pool = if(current_pool.flags.child == 0) return err else
                            @alignCast(@ptrCast(&current_pool.pool.?[0]));
                        continue :sw .free;
                    }
                }
            }
        }

        fn is_initialized(self_vtable: *const vtable.AllocVTable_T) bool {
            const self: *@This() = @alignCast(@ptrCast(self_vtable.private));
            return (self.root.pool != null);
        }

        pub fn allocator(self: *@This()) vtable.AllocVTable_T {
            return vtable.AllocVTable_T {
                .fn_init = &init,
                .fn_deinit = &deinit,
                .fn_alloc = &alloc,
                .fn_free = &free,
                .fn_is_initialized = &is_initialized,
                .private = self,
            };
        }
    };
}
