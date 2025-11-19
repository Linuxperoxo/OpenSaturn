// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: sba.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const std: type = @import("std");

// === Saturn Byte Allocator (FOR TEST) ===

var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
var allocator = gpa.allocator();

const total_bytes_of_pool_test: comptime_int = 4096;
const default_block_size: comptime_int = 16;
const total_bytes_of_pool = total_bytes_of_pool_test;

pub const Personality_T: type = struct {
    resize: bool = true,
    resizeErr: bool = false,
};

comptime {
    if(!builtin.is_test) {
        @compileError(
            \\ Only Test SBA Memory Allocator
        );
    }
}

pub fn buildByteAllocator(
    comptime block: ?comptime_int,
    comptime personality: Personality_T,
) type {
    return struct {
        root: Pool_T = .{},
        top: ?*Pool_T = null,
        pools: if(personality.resize) usize else void = if(personality.resize) 1 else {},

        // esse calculo e equivalente a fazer:
        //
        // var blocks_reserved = block / @sizeOf(Pool_T);
        // if((block % @sizeOf(Pool_T)) != 0) blocks_reserved += 1;
        pub const blocks_reserved = if(personality.resize) ((@sizeOf(Pool_T) + block_size - 1) / block_size) else 0;
        pub const block_size = block orelse default_block_size;

        pub const Pool_T: type = struct {
            bytes: ?[]u8 = null,
            refs: usize = blocks_reserved,
            next: ?usize = null,
            bitmap: [pool_bitmap_len]u1 = r: {
                var map = [_]u1 {
                    0
                } ** pool_bitmap_len;
                if(!personality.resize) break :r map;
                for(0..blocks_reserved) |i|
                    map[i] = 1;
                break :r map;
            },
            flags: packed struct(u8) {
                full: u1 = 0,
                hit: u2 = 0,
                parent: u1 = 0,
                reserved: u4 = 0,
            } = .{},
            private: Private_T = if(Private_T == void) {} else undefined,

            pub const pool_bitmap_len = total_bytes_of_pool / block_size;

            pub const Private_T: type = void;
        };

        pub const err_T: type = error {
            PoolInitFailed,
            PoolResizeFailed,
            OutOfMemory,
            IndexOutBounds,
            UndefinedAction,
            MemoryFrag,
            ZeroBytes,
            NonPoolInitialized,
            PoolOverflow,
            DoubleFree,
        };

        fn pool_init(pool: *Pool_T) err_T!void {
            pool.bytes = allocator.alloc(u8, total_bytes_of_pool_test) catch return err_T.PoolInitFailed;
        }

        fn pool_deinit(pool: *Pool_T) err_T!void {
            allocator.free(pool.bytes.?);
        }

        fn resize(self: *@This()) err_T!void {
            const pool_config = opaque {
                pub fn config(pool: *Pool_T) void {
                    for(0..blocks_reserved) |i| {
                        pool.bitmap[i] = 1;
                    }
                    for(blocks_reserved..Pool_T.pool_bitmap_len) |i| {
                        pool.bitmap[i] = 0;
                    }
                    pool.refs = blocks_reserved;
                    pool.next = null;
                    pool.flags = .{
                        .full = 0,
                        .hit = 0,
                        .parent = 0,
                        .reserved = 0,
                    };
                }
            }.config;
            const pool: *Pool_T = @ptrCast(@alignCast(&self.top.?.bytes.?[0]));
            try @call(.always_inline, pool_init, .{
                pool
            });
            @call(.always_inline, pool_config, .{
                pool
            });
            self.top.?.flags.parent = 1;
            self.top = pool;
            if(personality.resize) {
                self.pools += 1;
            }
        }

        inline fn check_blocks_range(pool: *Pool_T, blocks: usize, locale: usize, state: ?u1) struct { index: ?usize, result: bool } {
            return r: {
                if((locale + blocks) > pool.bitmap.len) break :r .{
                    .index = null,
                    .result = false,
                };
                for(locale..(locale + blocks)) |i| {
                    if(pool.bitmap[i] != state orelse 1) break :r .{
                        .index = @intCast(i),
                        .result = false,
                    };
                }
                break :r .{
                    .index = null,
                    .result = true,
                };
            };
        }

        inline fn cast_block_to_byte(blocks: usize) usize {
            return blocks * block_size;
        }

        inline fn cast_bytes_to_block(bytes: usize) usize {
            return @intCast((block_size + bytes - 1) / block_size);
        }

        inline fn mark_blocks(pool: *Pool_T, index: usize, blocks: usize) err_T!void {
            // total_bytes_of_pool / block_size = bitmap.len
            if((index + blocks) > pool.bitmap.len) {
                return err_T.IndexOutBounds;
            }
            for(index..(index + blocks)) |i|
                pool.bitmap[i] = 1;
        }

        inline fn found_pool_of_ptr(self: *@This(), ptr: []u8) struct { ?*Pool_T, ?*Pool_T } {
            var child_pool: ?*Pool_T = null;
            var parent_pool: ?*Pool_T = null;
            var current_pool: *Pool_T = &self.root;
            while(true) {
                if(check_bounds(current_pool, ptr)) {
                    child_pool = current_pool; break;
                }
                if(current_pool.flags.parent == 0) break;
                parent_pool = current_pool;
                current_pool = @alignCast(@ptrCast(&current_pool.bytes.?[0]));
            }
            return .{
                parent_pool,
                child_pool,
            };
        }

        inline fn check_bounds(pool: *Pool_T, ptr: []u8) bool {
            return if(@intFromPtr(ptr.ptr) < @intFromPtr(&pool.bytes.?[0])) false else (@intFromPtr(ptr.ptr) - @intFromPtr(&pool.bytes.?[0])) < total_bytes_of_pool;
        }

        fn alloc_sigle_frame(self: *@This(), bytes: usize) err_T![]u8 {
            if(self.root.flags.full == 1) return err_T.OutOfMemory;
            var index: usize = self.root.next orelse 0;
            const blocks_to_alloc: usize = cast_bytes_to_block(bytes);
            for(index..self.root.bitmap.len) |_| {
                const check = check_blocks_range(&self.root, blocks_to_alloc, index, 0);
                if(check.result) break;
                if(check.index == null) return err_T.MemoryFrag;
                index = check.index.? + 1;
            }
            try mark_blocks(&self.root, index, blocks_to_alloc);
            self.root.refs += blocks_to_alloc;
            self.root.flags.full = if(self.root.refs >= self.root.bitmap.len) 1 else 0;
            return self.root.bytes.?[cast_block_to_byte(index)..cast_block_to_byte(index + blocks_to_alloc)];
        }

        fn alloc_resized_frame(self: *@This(), bytes: usize) err_T![]u8 {
            var current_pool: *Pool_T = r: {
                if(self.top.?.flags.full == 1) try @call(.never_inline, resize, .{
                    self
                });
                break :r self.top.?;
            };
            var index: usize = current_pool.next orelse blocks_reserved;
            const blocks_to_alloc: usize = cast_bytes_to_block(bytes);
            for(index..current_pool.bitmap.len) |_| {
                const check = check_blocks_range(current_pool, blocks_to_alloc, index, 0);
                if(check.result) break;
                if(check.index == null) {
                    try @call(.never_inline, resize, .{
                        self
                    });
                    current_pool = self.top.?;
                    index = blocks_reserved;
                    break;
                }
                index = check.index.? + 1;
            }
            try mark_blocks(current_pool, index, blocks_to_alloc);
            current_pool.refs += blocks_to_alloc;
            current_pool.flags.full = if(current_pool.refs >= current_pool.bitmap.len) 1 else 0;
            return current_pool.bytes.?[cast_block_to_byte(index)..cast_block_to_byte(index + blocks_to_alloc)];
        }

        pub fn alloc(self: *@This(), comptime T: type, N: usize) err_T![]T {
            const bytes: usize = @sizeOf(T) * N;
            self.top = self.top orelse &self.root;
            if(bytes == 0) return err_T.ZeroBytes;
            if(self.root.bytes == null) {
                @branchHint(.cold);
                try @call(.never_inline, pool_init, .{
                    &self.root
                });
            }
            if(comptime personality.resize) {
                return @as([]T, @alignCast(@ptrCast(try @call(.always_inline, alloc_resized_frame, .{
                    self, bytes
                }))));
            }
            return @as([]T, @alignCast(@ptrCast(try @call(.always_inline, alloc_sigle_frame, .{
                self, bytes
            }))));
        }

        fn free_resized_frame(self: *@This(), ptr: []u8) err_T!void {
            const parent_pool, const alloc_pool = self.found_pool_of_ptr(ptr);
            if(alloc_pool == null) return err_T.IndexOutBounds;
            const block_to_free: usize = cast_bytes_to_block(ptr.len);
            const initial_block: usize = cast_bytes_to_block(
                @intFromPtr(ptr.ptr) - @intFromPtr(&alloc_pool.?.bytes.?[0])
            );
            const check = check_blocks_range(alloc_pool.?, block_to_free, initial_block, null); // NULL == 1
            if(check.index != null and !check.result) return err_T.DoubleFree;
            if((alloc_pool.?.refs - block_to_free) == blocks_reserved and parent_pool != null) {
                @branchHint(.cold);
                self.top = if(alloc_pool.?.flags.parent == 0) parent_pool else self.top;
                parent_pool.?.flags.parent = alloc_pool.?.flags.parent;
                try @call(.never_inline, pool_deinit, .{
                    alloc_pool.?
                });
                if(alloc_pool.?.flags.parent == 1) {
                    @branchHint(.cold);
                    const dest: *Pool_T = @alignCast(@ptrCast(&parent_pool.?.bytes.?[0]));
                    const src: *Pool_T = @alignCast(@ptrCast(&alloc_pool.?.bytes.?[0]));
                    dest.* = src.*;
                }
                self.pools -= 1;
                return;
            }
            for(initial_block..(initial_block + block_to_free)) |i| {
                alloc_pool.?.bitmap[i] = 0;
            }
            alloc_pool.?.refs -= block_to_free;
            alloc_pool.?.flags.full = 0;
        }

        fn free_single_frame(self: *@This(), ptr: []u8) err_T!void {
            if(self.root.bytes == null) return err_T.NonPoolInitialized;
            if(!check_bounds(&self.root, ptr)) return err_T.IndexOutBounds;
            const block_to_free: usize = cast_bytes_to_block(ptr.len);
            const initial_block: usize = cast_bytes_to_block(
                @intFromPtr(ptr.ptr) - @intFromPtr(&self.root.bytes.?[0])
            );
            const check = check_blocks_range(&self.root, block_to_free, initial_block, null); // NULL == 1
            if(check.index != null and !check.result) return err_T.DoubleFree;
            for(initial_block..(initial_block + block_to_free)) |i| {
                self.root.bitmap[i] = 0;
            }
            self.root.refs -= block_to_free;
            self.root.flags.full = 0;
        }

        pub fn free(self: *@This(), ptr: anytype) err_T!void {
            comptime {
                sw: switch(@typeInfo(@TypeOf(ptr))) {
                    .pointer => |ptr_info| {
                        if(ptr_info.size != .slice) continue :sw @typeInfo(void);
                    },
                    else => @compileError(
                        \\ expect slice to free
                    ),
                }
            }
            if(comptime personality.resize) {
                return @call(.always_inline, free_resized_frame, .{
                    self, ptr
                });
            }
            return @call(.always_inline, free_single_frame, .{
                self, ptr
            });
        }
    };
}
