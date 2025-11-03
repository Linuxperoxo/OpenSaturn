// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: sba.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const mm: type = @import("root").mm;
const config: type = @import("root").config;
const types: type = @import("types.zig");
const std: type = @import("std");

// === Saturn Byte Allocator ===

const total_bytes_of_pool_test: comptime_int = 4096;
const default_block_size: comptime_int = 16;
const total_bytes_of_pool = if(builtin.is_test) total_bytes_of_pool_test else switch(config.arch.options.Target) {
    .i386 => config.kernel.options.kernel_page_size,
    else => unreachable,
};

pub fn buildByteAllocator(
    comptime block: ?comptime_int,
    comptime personality: types.Personality_T,
) type {
    return struct {
        root: Pool_T = .{},
        top: ?*Pool_T = null,
        resized: if(builtin.is_test and personality.resize) bool else void = if(builtin.is_test and personality.resize) false else {},

        // esse calculo e equivalente a fazer:
        //
        // var blocks_reserved = block / @sizeOf(Pool_T);
        // if((block % @sizeOf(Pool_T)) != 0) blocks_reserved += 1;
        pub const blocks_reserved = if(personality.resize) ((@sizeOf(Pool_T) + block_size - 1) / block_size) else 0;
        pub const block_size = block orelse default_block_size;

        const Pool_T: type = struct {
            bytes: ?[]u8 = null,
            refs: usize = blocks_reserved,
            next: ?usize = null,
            bitmap: [total_bytes_of_pool / block_size]u1 = r: {
                var map = [_]u1 {
                    0
                } ** (total_bytes_of_pool / block_size);
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

            const Private_T: type = if(builtin.is_test) void else switch(config.arch.options.Target) {
                .i386 => mm.AllocPage_T,
                else => void,
            };
        };

        pub const err_T: type = error {
            PoolInitFailed,
            PoolResizeFailed,
            OutOfMemory,
            IndexOutBounds,
            UndefinedAction,
            MemoryFrag,
        };

        fn pool_init(pool: *Pool_T) err_T!void {
            if(builtin.is_test) {
                var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
                var allocator = gpa.allocator();
                pool.bytes = allocator.alloc(u8, total_bytes_of_pool_test) catch return err_T.PoolInitFailed;
                return;
            }
            switch(config.arch.options.Target) {
                .i386 => {
                    pool.private = @call(.never_inline, mm.alloc_page, .{}) catch return err_T.PoolInitFailed;
                    pool.bytes = pool.private.virtual;
                },
                else => unreachable,
            }
        }

        fn pool_deinit(pool: *Pool_T) err_T!void {
            if(builtin.is_test) return;
            switch(config.arch.options.Target) {
                .i386 => @call(.never_inline, mm.free_page, .{
                    &pool.private
                }) catch return err_T.PoolInitFailed,
                else => unreachable,
            }
        }

        fn resize(self: *@This()) err_T!void {
            const pool: *Pool_T = @ptrCast(@alignCast(&self.top.?.bytes.?[0]));
            try @call(.always_inline, pool_init, .{
                pool
            });
            pool.refs = 0;
            pool.flags = .{
                .full = 0,
                .hit = 0,
                .parent = 0,
            };
            pool.next = blocks_reserved;
            self.top.?.flags.parent = 1;
            self.top = pool;
            if(builtin.is_test and personality.resize) {
                self.resized = true;
            }
        }

        inline fn check_blocks_range(pool: *Pool_T, blocks: usize, locale: usize) struct { index: ?usize, result: bool } {
            return r: {
                if((locale + blocks) >= pool.bitmap.len) break :r .{
                    .index = null,
                    .result = false,
                };
                for(locale..(locale + blocks)) |i| {
                    if(pool.bitmap[i] == 1) break :r .{
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
            if((index + blocks) >= pool.bitmap.len) return err_T.IndexOutBounds;
            for(index..(index + blocks)) |i|
                pool.bitmap[i] = 1;
        }

        fn alloc_to_one_frame(self: *@This(), bytes: usize) err_T![]u8 {
            if(self.root.flags.full == 1) return err_T.OutOfMemory;
            var index: usize = self.root.next orelse 0;
            const blocks_to_alloc: usize = cast_bytes_to_block(bytes);
            for(index..self.root.bitmap.len) |_| {
                const check = check_blocks_range(&self.root, blocks_to_alloc, index);
                if(check.result) break;
                if(check.index == null) return err_T.MemoryFrag;
                index = check.index.? + 1;
            }
            try mark_blocks(&self.root, index, blocks_to_alloc);
            self.root.refs += blocks_to_alloc;
            self.root.flags.full = if(self.root.refs >= self.root.bitmap.len) 1 else 0;
            return self.root.bytes.?[cast_block_to_byte(index)..cast_block_to_byte(index + blocks_to_alloc)];
        }

        fn alloc_to_resized_frame(self: *@This(), bytes: usize) err_T![]u8 {
            var current_pool: *Pool_T = self.top.?;
            var index: usize = current_pool.next orelse blocks_reserved;
            const blocks_to_alloc: usize = cast_bytes_to_block(bytes);
            for(index..current_pool.bitmap.len) |_| {
                const check = check_blocks_range(current_pool, blocks_to_alloc, index);
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

        pub fn alloc(self: *@This(), bytes: usize) err_T![]u8 {
            self.top = self.top orelse &self.root;
            if(self.root.bytes == null) {
                @branchHint(.cold);
                try @call(.never_inline, pool_init, .{
                    &self.root
                });
            }
            if(personality.resize) {
                return @call(.always_inline, alloc_to_resized_frame, .{
                    self, bytes
                });
            }
            return @call(.always_inline, alloc_to_one_frame, .{
                self, bytes
            });
        }

        pub fn free(self: *@This(), ptr: []u8) err_T!void {
            _ = self;
            _ = ptr;
        }
    };
}

test "SBA Alloc Test For Single Frame" {
    const block_size: usize = 0x10;
    const SBA_T: type = buildByteAllocator(
        block_size,
        .{
            .resize = false,
        }
    );
    const TestErr_T: type = error {
        NonResize,
        ResizeOutOfTime,
        BlockAlignMiss,
    };
    var sba_allocator: SBA_T = .{};
    var old_ptr: ?[]u8 = null;
    for(0..comptime(sba_allocator.root.bitmap.len - 1)) |_| { // FIXME: -1
        const ptr = try sba_allocator.alloc(1);
        if(old_ptr != null) {
            if((@intFromPtr(ptr.ptr) - @intFromPtr(old_ptr.?.ptr)) != SBA_T.block_size) return TestErr_T.BlockAlignMiss;
        }
        old_ptr = ptr;
    }
}

test "SBA Alloc Test For Resized Frame" {
    const block_size: usize = 0x10;
    const SBA_T: type = buildByteAllocator(
        block_size,
        .{
            .resize = true,
        }
    );
    const TestErr_T: type = error {
        NonResize,
        ResizeOutOfTime,
        BlockAlignMiss,
    };
    var sba_allocator: SBA_T = .{};
    var old_ptr: ?[]u8 = null;
    for(SBA_T.blocks_reserved..comptime(sba_allocator.root.bitmap.len - SBA_T.blocks_reserved)) |_| {
        const ptr = try sba_allocator.alloc(1);
        if(old_ptr != null) {
            if((@intFromPtr(ptr.ptr) - @intFromPtr(old_ptr.?.ptr)) != SBA_T.block_size) return TestErr_T.BlockAlignMiss;
        }
        old_ptr = ptr;
    }
    if(sba_allocator.resized) return TestErr_T.ResizeOutOfTime;
    _ = try sba_allocator.alloc(1);
    if(!sba_allocator.resized) return TestErr_T.NonResize;
}
