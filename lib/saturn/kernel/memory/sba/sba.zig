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

const Err_T: type = if(!builtin.is_test) @import("root").lib.memory.allocator.Err_T else error {
    InitFailed,
    IndexOutBounds,
    WithoutMemory,
    AlreadyInitialized,
    NoNInitialized,
    InternalError,
};

const VTable_T: type = if(!builtin.is_test) @import("root").lib.memory.allocator.VTable_T else struct {
    alloc: *const fn(alloc_self: *anyopaque, len: usize) Err_T![]u8,
    free: *const fn(alloc_self: *anyopaque, ptr: []u8) Err_T!void,
    init: *const fn(alloc_self: *anyopaque) Err_T!void,
    deinit: *const fn(alloc_self: *anyopaque) Err_T!void,
    is_initialized: *const fn(alloc_self: *anyopaque) bool,
};

const Allocator_T: type = if(!builtin.is_test) @import("root").lib.memory.allocator.Allocator_T else struct {
    vtable: *const VTable_T,
    private: *anyopaque,

    pub fn alloc(self: Allocator_T, comptime T: type, num: usize) Err_T![]T {
        return @alignCast(@ptrCast(
            (try self.vtable.alloc(self.private, num))[0..(@sizeOf(T) * num)]
        ));
    }

    pub fn free(self: Allocator_T, ptr: anytype) Err_T!void {
        const ptr_size, const ptr_child = comptime sw: switch(@typeInfo(@TypeOf(ptr))) {
            .pointer => |ptr_info| {
                if(ptr_info.size == .c or ptr_info.size == .many)
                    continue :sw @typeInfo(void);
                break :sw .{
                    ptr_info.size,
                    ptr_info.child
                };
            },
            else => @compileError("expect slice or single pointer to free. Found \"" ++ @typeName(@TypeOf(ptr)) ++ "\""),
        };
        const slice = ptr[0..@sizeOf(ptr_child) * (
            if(comptime ptr_size == .one) 1 else ptr.len
        )];
        return self.vtable.free(self.private, slice);
    }

    pub fn init(self: Allocator_T) Err_T!void {
        return self.vtable.init(self.private);
    }

    pub fn deinit(self: Allocator_T) void {
        return self.vtable.deinit(self.private);
    }

    pub fn is_initialized(self: Allocator_T) bool {
        return self.vtable.is_initialized(self.private);
    }
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
            size: usize = block_size,
            blocks: usize = vector_blocks,
            bmarks: usize = 0,
        } else void;

        const block_size: comptime_int = block orelse default_block_size;
        const vector_blocks: comptime_int = total_bytes_of_pool / block_size;

        const BitmapInt_T: type = @Type(.{
            .int = .{
                .bits = vector_blocks,
                .signedness = .unsigned,
            },
        });

        const ExpectInt_T: type = @Type(.{
            .int = .{
                .bits = vector_blocks + 1,
                .signedness = .unsigned,
            },
        });

        const Bitmap_T: type = @Vector(vector_blocks, u1);

        pub const Pool_T: type = struct {
            pool: ?*[total_bytes_of_pool]u8 = null,
            prev: ?*Pool_T = null,
            bitmap: Bitmap_T = @splat(1),
            private: ?*anyopaque = null,
            flags: packed struct {
                child: u1 = 0,
                full: u1 = 0,
            } = .{},

            // ============================== TEST
            inline fn test_init_pool(self: *@This()) Err_T!void {
                var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
                var gpa_allocator = gpa.allocator();
                self.pool = @alignCast(@ptrCast(gpa_allocator.alloc(u8, total_bytes_of_pool) catch unreachable));
                self.private = &gpa_allocator;
            }

            inline fn test_deinit_pool(_: *@This()) Err_T!void {
                return;
            }
            // ==============================

            // ============================ TARGET
            inline fn target_init_pool(self: *@This()) Err_T!void {
                switch(comptime ar.target_code.target) {
                    .i386 => {
                        const page = ar.target_code.mm.alloc_page()
                            catch return Err_T.InternalError;
                        self.pool = page.virtual;
                        self.private = page;
                    },
                    else => @compileError(""),
                }
            }

            inline fn target_deinit_pool(_: *@This()) Err_T!void {
                switch(comptime ar.target_code.target) {
                    .i386 => {
                        
                    },
                    else => @compileError(""),
                }
            }
            // ==================================

            // ================================== AUX
            inline fn child(self: *@This()) *Pool_T {
                return @alignCast(@ptrCast(&self.pool.?[0]));
            }

            inline fn initialized(self: *@This()) Err_T!void {
                return if(self.pool == null) Err_T.NoNInitialized else
                    {};
            }

            inline fn any(self: *@This()) Err_T!void {
                return if(@as(BitmapInt_T, @bitCast(self.bitmap)) == 0 or self.flags.full == 1) Err_T.WithoutMemory else
                    {};
            }

            inline fn outbounds(self: *@This(), ptr: []u8) Err_T!void {
                return if((@intFromPtr(ptr.ptr) - @intFromPtr(self.pool.?)) > total_bytes_of_pool) Err_T.IndexOutBounds else
                    {};
            }

            inline fn empty(self: *@This()) bool {
                return ~@as(BitmapInt_T, @bitCast(self.bitmap)) == 0;
            }
            // ====================================

            pub noinline fn init(self: *@This()) Err_T!void {
                self.* = .{};
                return if(!builtin.is_test) self.target_init_pool() else
                    self.test_init_pool();
            }

            pub noinline fn deinit(self: *@This()) Err_T!void {
                if(self.pool == null) return;
                if(!builtin.is_test) try self.target_deinit_pool() else
                    try self.test_deinit_pool();
                self.* = .{};
            }

            pub noinline fn alloc(self: *@This(), bytes: usize) Err_T![]u8 {
                try self.initialized();
                try self.any();

                const blocks: usize = (block_size + (bytes - 1)) / block_size;
                // ExpectInt_T deve ter 1 bit extra que BitmapInt_T isso evita um overflow fazendo shift em @intCast(blocks) caso
                // blocks for exatamente o tamanho total do bitmap
                const expect: BitmapInt_T = @truncate((@as(ExpectInt_T, 1) << @intCast(blocks)) - 1);

                var bitmap: BitmapInt_T = @bitCast(self.bitmap);
                var ctz: usize = @ctz(bitmap);
                var initial_block_index: usize = ctz;

                bitmap >>= @intCast(ctz);

                r: {
                    while(bitmap != 0) {
                        if((bitmap & expect) == expect)
                            break :r {};
                        bitmap >>= @intCast(blocks);
                        ctz = @ctz(bitmap);
                        bitmap >>= @intCast(ctz);
                        initial_block_index += (blocks + ctz);
                    }
                    return Err_T.WithoutMemory;
                }

                const pool_initial_index: usize = initial_block_index * block_size;
                const pool_final_index: usize = pool_initial_index + (blocks * block_size);

                for(0..blocks) |i|
                    self.bitmap[initial_block_index + i] = 0;
                self.flags.full = @intFromBool((bitmap >> @intCast(blocks)) == 0);

                return self.pool.?[pool_initial_index..pool_final_index];
            }

            pub noinline fn free(self: *@This(), ptr: []u8) Err_T!void {
                try self.initialized();
                try self.outbounds(ptr);

                const blocks: usize = (block_size + (ptr.len - 1)) / block_size;
                const initial_block_index: usize = (@intFromPtr(ptr.ptr) - @intFromPtr(self.pool.?)) / block_size;

                for(0..blocks) |i| {
                    self.bitmap[initial_block_index + i] = 1;
                }
                self.flags.full = 0;
            }
        };

        root: Pool_T = .{},
        debug: Debug_T = .{},

        noinline fn init(context: *anyopaque) Err_T!void {
            const self: *@This() = @alignCast(@ptrCast(context));
            try self.root.init();
            // ============== DEBUG
            if(comptime options.debug) {
                self.debug.pools += 1;
            }
            // =====================
        }

        noinline fn deinit(context: *anyopaque) Err_T!void {
            const self: *@This() = @alignCast(@ptrCast(context));
            try self.root.deinit();
            // ============== DEBUG
            if(comptime options.debug) {
                self.debug.pools -= 1;
            }
            // =====================
        }

        noinline fn alloc(context: *anyopaque, bytes: usize) Err_T![]u8 {
            const self: *@This() = @as(*@This(), @alignCast(@ptrCast(context)));
            var current_pool: *Pool_T = &self.root;
            while(true) {
                while(current_pool.alloc(bytes)) |allocation| {
                    // ============= DEBUG
                    if(comptime options.debug) {
                        self.debug.allocs += 1;
                        self.debug.bytes += bytes;
                    }
                    // ==================
                    return allocation;
                } else |err| switch(err) {
                    Err_T.WithoutMemory => {
                        if(comptime !options.resize) return err;
                        if(current_pool.flags.child == 0) {
                            try current_pool.child().init();
                            current_pool.flags.child = 1;
                            // ============== DEBUG
                            if(comptime options.debug) {
                                self.debug.pools += 1;
                            }
                            // =====================
                        }
                        current_pool = current_pool.child();
                    },
                    else => return err,
                }
            }
            unreachable;
        }

        noinline fn free(context: *anyopaque , ptr: []u8) Err_T!void {
            const self: *@This() = @as(*@This(), @alignCast(@ptrCast(context)));
            var current_pool: *Pool_T = &self.root;
            while(true) {
                while(current_pool.free(ptr)) |_| {
                    if(current_pool.empty() and current_pool.flags.child == 1) {
                        if(current_pool.prev == null) {
                            const child_pool: Pool_T = current_pool.child().*;
                            try current_pool.deinit();
                            current_pool.* = child_pool;
                        } else {
                            @as(*Pool_T, @alignCast(@ptrCast(&current_pool.prev.?.pool.?[0]))).*
                                = @as(*Pool_T, @alignCast(@ptrCast(&current_pool.pool.?[0]))).*;
                            try current_pool.deinit();
                        }
                        // ============= DEBUG
                        if(comptime options.debug) {
                            self.debug.pools -= 1;
                        }
                        // ===================
                    }
                    // ============= DEBUG
                    if(comptime options.debug) {
                        self.debug.allocs -= 1;
                        self.debug.bytes -= ptr.len;
                    }
                    // ===================
                    return;
                } else |err| switch(err) {
                    Err_T.IndexOutBounds => {
                        if(comptime !options.resize) return err;
                        if(current_pool.flags.child == 0) return err;
                        current_pool = current_pool.child();
                    },
                    else => return err,
                }
            }
            unreachable;
        }

        noinline fn is_initialized(context: *anyopaque) bool {
            const self: *@This() = @alignCast(@ptrCast(context));
            return (self.root.pool != null);
        }

        pub inline fn allocator(self: *@This()) Allocator_T {
            return Allocator_T {
                .private = self,
                .vtable = &VTable_T {
                    .alloc = &alloc,
                    .free = &free,
                    .init = &init,
                    .deinit = &deinit,
                    .is_initialized = &is_initialized,
                }
            };
        }
    };
}

// TEST WITHOUT RESIZE

test "Full Alloc" {
    var sba = buildByteAllocator(null, .{
        .resize = false,
        .debug = true,
    }) {};

    var allocator = sba.allocator();
    try allocator.init();

    var current: []u8 = undefined;
    var prev: []u8 = @as([*]u8, @ptrFromInt(0x10))[0..1];

    for(0..sba.debug.blocks) |_| {
        current = try allocator.alloc(u8, 1);
        if(@intFromPtr(current.ptr) <= @intFromPtr(prev.ptr))
            return error.PointerOverrider;
        prev = current;
    }
    if(allocator.alloc(u8, 1)) |_| {
        return error.AllocWithoutSpace;
    } else |_| {
        return;
    }
}

test "Full Free" {

}

// TEST WITH RESIZE

test "Resized Full Alloc" {
    var sba = buildByteAllocator(null, .{
        .resize = true,
        .debug = true,
    }) {};

    var allocator = sba.allocator();
    try allocator.init();

    var current: []u8 = undefined;
    //var prev: []u8 = @as([*]u8, @ptrFromInt(0x10))[0..1];

    for(0..sba.debug.blocks * 12) |_| {
        current = try allocator.alloc(u8, 1);
    }

    if(sba.debug.pools != 12)
        return error.ResizeMiss;

    std.debug.print("{any}\n", .{
        sba.debug
    });
}
