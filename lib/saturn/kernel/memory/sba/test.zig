// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Teste Info ===
//
// OS: Gentoo Linux x86_64
// Zig: 0.15.2
// Tester: Linuxperoxo
// Status: Pass

const buildByteAllocator = @import("sba.zig").buildByteAllocator;

const TestSingleErr_T: type = error {
    BlockAlignMiss,
    NonFullAlloc,
};

const TestResizedErr_T: type = TestSingleErr_T || error {
    NonResize,
    ResizeOutOfTime,
};

test "SBA Alloc Test For Single Frame" {
    const block_size: usize = 0x10;
    const SBA_T: type = buildByteAllocator(
        block_size,
        .{
            .resize = false,
        }
    );
    var sba_allocator: SBA_T = .{};
    var old_ptr: ?[]u8 = null;
    for(0..SBA_T.Pool_T.pool_bitmap_len) |_| {
        const ptr = try sba_allocator.alloc(1);
        if(old_ptr != null) {
            if((@intFromPtr(ptr.ptr) - @intFromPtr(old_ptr.?.ptr)) != SBA_T.block_size) return TestSingleErr_T.BlockAlignMiss;
        }
        old_ptr = ptr;
    }
    for(0..SBA_T.Pool_T.pool_bitmap_len) |i| {
        if(sba_allocator.root.bitmap[i] == 0) return TestSingleErr_T.NonFullAlloc;
    }
}

test "SBA Free Test For Single Frame" {
    const block_size: usize = 0x10;
    const SBA_T: type = buildByteAllocator(
        block_size,
        .{
            .resize = false,
        }
    );
    var sba_allocator: SBA_T = .{};
    for(0..SBA_T.Pool_T.pool_bitmap_len) |_| {
        _ = try sba_allocator.alloc(1);
    }
    for(0..SBA_T.Pool_T.pool_bitmap_len) |i| {
        try sba_allocator.free(
            @as([*]u8, @ptrCast(&sba_allocator.root.bytes.?[i * SBA_T.block_size]))[0..1]
        );
    }
    for(0..SBA_T.Pool_T.pool_bitmap_len) |_| {
        _ = try sba_allocator.alloc(1);
    }
    for(0..SBA_T.Pool_T.pool_bitmap_len) |i| {
        try sba_allocator.free(
            @as([*]u8, @ptrCast(&sba_allocator.root.bytes.?[i * SBA_T.block_size]))[0..1]
        );
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
    var sba_allocator: SBA_T = .{};
    var old_ptr: ?[]u8 = null;
    for(SBA_T.blocks_reserved..SBA_T.Pool_T.pool_bitmap_len) |_| {
        const ptr = try sba_allocator.alloc(1);
        if(old_ptr != null) {
            if((@intFromPtr(ptr.ptr) - @intFromPtr(old_ptr.?.ptr)) != SBA_T.block_size) return TestResizedErr_T.BlockAlignMiss;
        }
        old_ptr = ptr;
    }
    for(0..SBA_T.Pool_T.pool_bitmap_len) |i| {
        if(sba_allocator.root.bitmap[i] == 0) return TestResizedErr_T.NonFullAlloc;
    }
    // resized test
    if(sba_allocator.resized) return TestResizedErr_T.ResizeOutOfTime;
    _ = try sba_allocator.alloc(1);
    if(!sba_allocator.resized) return TestResizedErr_T.NonResize;
    old_ptr = null;
    for(SBA_T.blocks_reserved..SBA_T.Pool_T.pool_bitmap_len - 1) |_| {
        const ptr = try sba_allocator.alloc(1);
        if(old_ptr != null) {
            if((@intFromPtr(ptr.ptr) - @intFromPtr(old_ptr.?.ptr)) != SBA_T.block_size) return TestResizedErr_T.BlockAlignMiss;
        }
        old_ptr = ptr;
    }
    for(0..SBA_T.Pool_T.pool_bitmap_len) |i| {
        if(sba_allocator.top.?.bitmap[i] == 0) return TestResizedErr_T.NonFullAlloc;
    }
}

test "SBA Free Test For Resized Frame" {
    const block_size: usize = 0x10;
    const SBA_T: type = buildByteAllocator(
        block_size,
        .{
            .resize = true,
        }
    );
    var sba_allocator: SBA_T = .{};
    for(SBA_T.blocks_reserved..SBA_T.Pool_T.pool_bitmap_len) |_| {
        _ = try sba_allocator.alloc(1);
    }
}
