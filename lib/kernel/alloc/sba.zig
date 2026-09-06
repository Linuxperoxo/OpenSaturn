// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: sba.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const mm: type = @import("root").__SaturnArchImpl__.mm;
const config: type = @import("root").config;
const types: type = @import("sba/types.zig");

// === Saturn Byte Allocator ===

const default_block_size: comptime_int = 16;
const total_bytes_of_pool = switch (config.arch.options.target) {
    .i386 => config.kernel.options.kernel_page_size,
    else => unreachable,
};

pub fn buildByteAllocator(
    comptime block: ?comptime_int,
    comptime personality: types.Personality,
) type {
    return struct {
        root: Pool = .{},
        top: ?*Pool = null,

        // esse calculo e equivalente a fazer:
        //
        // var blocks_reserved = block / @sizeOf(Pool);
        // if((block % @sizeOf(Pool)) != 0) blocks_reserved += 1;
        pub const blocks_reserved = if (personality.resize) ((@sizeOf(Pool) + block_size - 1) / block_size) else 0;
        pub const block_size = block orelse default_block_size;

        pub const Pool: type = struct {
            bytes: ?[]u8 = null,
            refs: usize = blocks_reserved,
            next: ?usize = null,
            bitmap: [pool_bitmap_len]u1 = r: {
                var map = [_]u1{0} ** pool_bitmap_len;
                if (!personality.resize) break :r map;
                for (0..blocks_reserved) |i|
                    map[i] = 1;
                break :r map;
            },
            flags: packed struct(u8) {
                full: u1 = 0,
                hit: u2 = 0,
                parent: u1 = 0,
                reserved: u4 = 0,
            } = .{},
            private: Private = if (Private == void) {} else undefined,

            pub const pool_bitmap_len = total_bytes_of_pool / block_size;

            pub const Private: type = switch (config.arch.options.target) {
                .i386 => mm.AllocPage,
                else => void,
            };
        };

        pub const Err: type = error{
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

        fn poolInit(pool: *Pool) Err!void {
            switch (config.arch.options.target) {
                .i386 => {
                    pool.private = @call(.never_inline, mm.allocPage, .{}) catch return Err.PoolInitFailed;
                    pool.bytes = pool.private.virtual;
                },
                else => unreachable,
            }
        }

        fn poolDeinit(pool: *Pool) Err!void {
            switch (config.arch.options.target) {
                .i386 => @call(.never_inline, mm.freePage, .{&pool.private}) catch return Err.PoolInitFailed,
                else => unreachable,
            }
        }

        fn resize(self: *@This()) Err!void {
            const poolConfig = opaque {
                pub fn config(pool: *Pool) void {
                    for (0..blocks_reserved) |i| {
                        pool.bitmap[i] = 1;
                    }
                    for (blocks_reserved..Pool.pool_bitmap_len) |i| {
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
            const pool: *Pool = @ptrCast(@alignCast(&self.top.?.bytes.?[0]));
            try @call(.always_inline, poolInit, .{pool});
            @call(.always_inline, poolConfig, .{pool});
            self.top.?.flags.parent = 1;
            self.top = pool;
        }

        inline fn checkBlocksRange(pool: *Pool, blocks: usize, locale: usize, state: ?u1) struct { index: ?usize, result: bool } {
            return r: {
                if ((locale + blocks) > pool.bitmap.len) break :r .{
                    .index = null,
                    .result = false,
                };
                for (locale..(locale + blocks)) |i| {
                    if (pool.bitmap[i] != state orelse 1) break :r .{
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

        inline fn castBlockToByte(blocks: usize) usize {
            return blocks * block_size;
        }

        inline fn castBytesToBlock(bytes: usize) usize {
            return @intCast((block_size + bytes - 1) / block_size);
        }

        inline fn markBlocks(pool: *Pool, index: usize, blocks: usize) Err!void {
            // total_bytes_of_pool / block_size = bitmap.len
            if ((index + blocks) > pool.bitmap.len) return Err.IndexOutBounds;
            for (index..(index + blocks)) |i|
                pool.bitmap[i] = 1;
        }

        inline fn foundPoolOfPtr(self: *@This(), ptr: []u8) struct { ?*Pool, ?*Pool } {
            var child_pool: ?*Pool = null;
            var parent_pool: ?*Pool = null;
            var current_pool: *Pool = &self.root;
            while (true) {
                if (checkBounds(current_pool, ptr)) {
                    child_pool = current_pool;
                    break;
                }
                if (current_pool.flags.parent == 0) break;
                parent_pool = current_pool;
                current_pool = @ptrCast(@alignCast(&current_pool.bytes.?[0]));
            }
            return .{
                parent_pool,
                child_pool,
            };
        }

        inline fn checkBounds(pool: *Pool, ptr: []u8) bool {
            return if (@intFromPtr(ptr.ptr) < @intFromPtr(&pool.bytes.?[0])) false else (@intFromPtr(ptr.ptr) - @intFromPtr(&pool.bytes.?[0])) < total_bytes_of_pool;
        }

        fn allocSigleFrame(self: *@This(), bytes: usize) Err![]u8 {
            if (self.root.flags.full == 1) return Err.OutOfMemory;

            const blocks_to_alloc: usize = castBytesToBlock(bytes);
            var index: usize = self.root.next orelse 0;

            for (index..self.root.bitmap.len) |_| {
                const check = checkBlocksRange(&self.root, blocks_to_alloc, index, 0);
                if (check.result) break;
                if (check.index == null) return Err.MemoryFrag;
                index = check.index.? + 1;
            }
            try markBlocks(&self.root, index, blocks_to_alloc);

            self.root.refs += blocks_to_alloc;
            self.root.flags.full = if (self.root.refs >= self.root.bitmap.len) 1 else 0;

            return self.root.bytes.?[castBlockToByte(index)..castBlockToByte(index + blocks_to_alloc)];
        }

        fn allocResizedFrame(self: *@This(), bytes: usize) Err![]u8 {
            var current_pool: *Pool = r: {
                if (self.top.?.flags.full == 1) try @call(.never_inline, resize, .{self});
                break :r self.top.?;
            };
            const blocks_to_alloc: usize = castBytesToBlock(bytes);
            var index: usize = current_pool.next orelse blocks_reserved;

            for (index..current_pool.bitmap.len) |_| {
                const check = checkBlocksRange(current_pool, blocks_to_alloc, index, 0);
                if (check.result) break;
                if (check.index == null) {
                    try @call(.never_inline, resize, .{self});
                    current_pool = self.top.?;
                    index = blocks_reserved;
                    break;
                }
                index = check.index.? + 1;
            }
            try markBlocks(current_pool, index, blocks_to_alloc);

            current_pool.refs += blocks_to_alloc;
            current_pool.flags.full = if (current_pool.refs >= current_pool.bitmap.len) 1 else 0;

            return current_pool.bytes.?[castBlockToByte(index)..castBlockToByte(index + blocks_to_alloc)];
        }

        pub fn alloc(self: *@This(), comptime t: type, n: usize) Err![]t {
            const bytes: usize = @sizeOf(t) * n;
            self.top = self.top orelse &self.root;
            if (bytes == 0) return Err.ZeroBytes;
            if (self.root.bytes == null) {
                @branchHint(.cold);
                try @call(.never_inline, poolInit, .{&self.root});
            }
            if (comptime personality.resize) {
                return @as([]t, @ptrCast(@alignCast(try @call(.always_inline, allocResizedFrame, .{ self, bytes }))))[0..n];
            }
            return @as([]t, @ptrCast(@alignCast(try @call(.always_inline, allocSigleFrame, .{ self, bytes }))))[0..n];
        }

        fn freeResizedFrame(self: *@This(), ptr: []u8) Err!void {
            const parent_pool, const alloc_pool = self.foundPoolOfPtr(ptr);
            if (alloc_pool == null)
                return Err.IndexOutBounds;

            const block_to_free: usize = castBytesToBlock(ptr.len);
            const initial_block: usize = castBytesToBlock(@intFromPtr(ptr.ptr) - @intFromPtr(&alloc_pool.?.bytes.?[0]));

            const check = checkBlocksRange(alloc_pool.?, block_to_free, initial_block, null); // NULL == 1
            if (check.index != null and !check.result)
                return Err.DoubleFree;

            if ((alloc_pool.?.refs - block_to_free) == blocks_reserved and parent_pool != null) {
                @branchHint(.cold);
                self.top = if (alloc_pool.?.flags.parent == 0) parent_pool else self.top;
                parent_pool.?.flags.parent = alloc_pool.?.flags.parent;
                try @call(.never_inline, poolDeinit, .{alloc_pool.?});
                if (alloc_pool.?.flags.parent == 1) {
                    @branchHint(.cold);
                    const dest: *Pool = @ptrCast(@alignCast(&parent_pool.?.bytes.?[0]));
                    const src: *Pool = @ptrCast(@alignCast(&alloc_pool.?.bytes.?[0]));
                    dest.* = src.*;
                }
                return;
            }

            for (initial_block..(initial_block + block_to_free)) |i| {
                alloc_pool.?.bitmap[i] = 0;
            }
            alloc_pool.?.refs -= block_to_free;
            alloc_pool.?.flags.full = 0;
        }

        fn freeSingleFrame(self: *@This(), ptr: []u8) Err!void {
            if (self.root.bytes == null) return Err.NonPoolInitialized;
            if (!checkBounds(&self.root, ptr))
                return Err.IndexOutBounds;

            const block_to_free: usize = castBytesToBlock(ptr.len);
            const initial_block: usize = castBytesToBlock(@intFromPtr(ptr.ptr) - @intFromPtr(&self.root.bytes.?[0]));

            const check = checkBlocksRange(&self.root, block_to_free, initial_block, null); // NULL == 1
            if (check.index != null and !check.result)
                return Err.DoubleFree;

            for (initial_block..(initial_block + block_to_free)) |i| {
                self.root.bitmap[i] = 0;
            }
            self.root.refs -= block_to_free;
            self.root.flags.full = 0;
        }

        pub fn free(self: *@This(), ptr: anytype) Err!void {
            const byteSliceFn = comptime sw0: switch (@typeInfo(@TypeOf(ptr))) {
                .pointer => |ptr_info| {
                    switch (ptr_info.size) {
                        .slice => break :sw0 opaque {
                            pub fn cast(slice: []ptr_info.child) []u8 {
                                return @as([]u8, @ptrCast(slice));
                            }
                        }.cast,
                        .one => break :sw0 opaque {
                            pub fn cast(single: *ptr_info.child) []u8 {
                                return @as([]u8, @ptrCast(@as([*]ptr_info.child, @ptrCast(single))[0..1]));
                            }
                        }.cast,
                        else => continue :sw0 @typeInfo(void),
                    }
                },
                else => @compileError("expect slice to free or single pointer"),
            };
            const byte_slice = @call(.always_inline, byteSliceFn, .{ptr});
            if (comptime personality.resize) {
                return @call(.always_inline, freeResizedFrame, .{ self, byte_slice });
            }
            return @call(.always_inline, freeSingleFrame, .{ self, byte_slice });
        }
    };
}
