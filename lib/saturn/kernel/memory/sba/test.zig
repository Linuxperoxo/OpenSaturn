// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Teste Info ===
//
// OS: Gentoo Linux x86_64
// Zig: 0.15.2
// Tester: Linuxperoxo
// Status: OK

const std: type = @import("std");

const block_size: usize = 0x10;

const buildByteAllocator = @import("sba.zig").buildByteAllocator;

const TestSingleErr_T: type = error {
    BlockAlignMiss,
    NonFullAlloc,
    NonFullFree,
};

const TestResizedErr_T: type = TestSingleErr_T || error {
    NonResize,
    ResizeOutOfTime,
    InvalidPoolNum,
    NonNewFrame,
    NonReachRoot,
    InvalidParent,
};

const SBASingle_T: type = buildByteAllocator(
    block_size,
    .{
        .resize = false,
    }
);

const SBASinglePool_T: type = SBASingle_T.Pool_T;

const SBAResized_T: type = buildByteAllocator(
    block_size,
    .{
        .resize = true,
    }
);

const SBAResizedPool_T: type = SBAResized_T.Pool_T;

fn full_alloc(comptime SBA_T: type, allocator: *SBA_T) anyerror!void {
    for(if(SBA_T == SBASingle_T) 0 else SBA_T.blocks_reserved..SBA_T.Pool_T.pool_bitmap_len) |_| {
        _ = try allocator.alloc(u8, 1);
    }
}

fn full_free(comptime SBA_T: type, pool: *SBA_T.Pool_T, allocator: *SBA_T, index: usize) anyerror!void {
    for(index..SBA_T.Pool_T.pool_bitmap_len) |i| {
        const slice: []u8 =  @as([*]u8, @alignCast(@ptrCast(&pool.bytes.?[i * SBA_T.block_size])))[0..1];
        try allocator.free(
            slice
        );
    }
}

fn bitmap_check(comptime Pool_T: type, pool: *Pool_T, state: u1, index: usize) bool {
    for(index..Pool_T.pool_bitmap_len) |i| {
        if(pool.bitmap[i] != state) return false;
    }
    return true;
}

test "SBA Alloc Test For Single Frame" {
    var sba_allocator: SBASingle_T = .{};
    var old_ptr: ?[]u8 = null;
    for(0..SBASingle_T.Pool_T.pool_bitmap_len) |_| {
        const ptr = try sba_allocator.alloc(u8, 1);
        if(old_ptr != null) {
            if((@intFromPtr(ptr.ptr) - @intFromPtr(old_ptr.?.ptr)) != SBASingle_T.block_size) return TestSingleErr_T.BlockAlignMiss;
        }
        old_ptr = ptr;
    }
    if(!bitmap_check(SBASingle_T.Pool_T, &sba_allocator.root, 1, 0)) return TestSingleErr_T.NonFullAlloc;
}

test "SBA Free Test For Single Frame" {
    var sba_allocator: SBASingle_T = .{};
    for(0..4) |_| {
        try full_alloc(SBASingle_T, &sba_allocator);
        try full_free(SBASingle_T, &sba_allocator.root, &sba_allocator, 0);
    }
    if(!bitmap_check(SBASingle_T.Pool_T, &sba_allocator.root, 0, 0)) return TestSingleErr_T.NonFullFree;
}

test "SBA Alloc Test For Resized Frame" {
    var sba_allocator: SBAResized_T = .{};
    var old_ptr: ?[]u8 = null;
    for(SBAResized_T.blocks_reserved..SBAResized_T.Pool_T.pool_bitmap_len) |_| {
        const ptr = try sba_allocator.alloc(u8, 1);
        if(old_ptr != null) {
            if((@intFromPtr(ptr.ptr) - @intFromPtr(old_ptr.?.ptr)) != SBAResized_T.block_size) return TestResizedErr_T.BlockAlignMiss;
        }
        old_ptr = ptr;
    }
    if(!bitmap_check(SBAResized_T.Pool_T, sba_allocator.top.?, 1, SBAResized_T.blocks_reserved)) return TestResizedErr_T.NonFullAlloc;

    // resized test

    if(sba_allocator.pools > 1) return TestResizedErr_T.ResizeOutOfTime;
    _ = try sba_allocator.alloc(u8, 1);
    if(sba_allocator.pools == 1) return TestResizedErr_T.NonResize;
    old_ptr = null;
    for(SBAResized_T.blocks_reserved..SBAResized_T.Pool_T.pool_bitmap_len - 1) |_| {
        const ptr = try sba_allocator.alloc(u8, 1);
        if(old_ptr != null) {
            if((@intFromPtr(ptr.ptr) - @intFromPtr(old_ptr.?.ptr)) != SBAResized_T.block_size) return TestResizedErr_T.BlockAlignMiss;
        }
        old_ptr = ptr;
    }
    if(!bitmap_check(SBAResized_T.Pool_T, sba_allocator.top.?, 1, SBAResized_T.blocks_reserved)) return TestResizedErr_T.NonFullAlloc;
}

test "SBA Free Test For Resized Root Frame" {
    var sba_allocator: SBAResized_T = .{};
    try full_alloc(SBAResized_T, &sba_allocator);
    try full_free(SBAResized_T, sba_allocator.top.?, &sba_allocator, SBAResized_T.blocks_reserved);
    full_free(SBAResized_T, sba_allocator.top.?, &sba_allocator, SBAResized_T.blocks_reserved) catch |err| switch(err) {
        SBAResized_T.err_T.DoubleFree => {},
        else => return err,
    };
    if(!bitmap_check(SBAResized_T.Pool_T, sba_allocator.top.?, 0, SBAResized_T.blocks_reserved)) return TestResizedErr_T.NonFullFree;
}

test "SBA Free Test For Resized Top Frame" {
    var sba_allocator: SBAResized_T = .{};
    for(0..4) |_| {
        try full_alloc(SBAResized_T, &sba_allocator);
    }
    for(0..4) |_| {
        try full_free(SBAResized_T, sba_allocator.top.?, &sba_allocator, SBAResized_T.blocks_reserved);
    }
    if(&sba_allocator.root != sba_allocator.top.?) return TestResizedErr_T.NonReachRoot;
    if(sba_allocator.root.flags.parent == 1) return TestResizedErr_T.InvalidParent;
    if(sba_allocator.pools > 1) return TestResizedErr_T.InvalidPoolNum;
    if(sba_allocator.root.refs != SBAResized_T.blocks_reserved) return TestResizedErr_T.NonFullFree;
}

test "SBA Free Test For Resized Mid Frame" {
    var sba_allocator: SBAResized_T = .{};
    for(0..64) |_| {
        try full_alloc(SBAResized_T, &sba_allocator);
    }
    const pool: *SBAResized_T.Pool_T = @alignCast(@ptrCast(&sba_allocator.root.bytes.?[0]));
    for(0..63) |_| {
        try full_free(SBAResized_T, pool, &sba_allocator, SBAResized_T.blocks_reserved);
    }
    try full_free(SBAResized_T, sba_allocator.top.?, &sba_allocator, SBAResized_T.blocks_reserved);
    if(&sba_allocator.root != sba_allocator.top.?) return TestResizedErr_T.NonReachRoot;
    if(sba_allocator.root.flags.parent == 1) return TestResizedErr_T.InvalidParent;
    if(sba_allocator.pools > 1) return TestResizedErr_T.InvalidPoolNum;
    if(sba_allocator.root.refs != SBAResized_T.blocks_reserved) return TestResizedErr_T.NonFullFree;
}

test "SBA Resize After Free For Resized Frame" {
    var sba_allocator: SBAResized_T = .{};
    try full_alloc(SBAResized_T, &sba_allocator);
    try full_alloc(SBAResized_T, &sba_allocator);
    try full_free(SBAResized_T, sba_allocator.top.?, &sba_allocator, SBAResized_T.blocks_reserved);
    if(&sba_allocator.root != sba_allocator.top.?) return TestResizedErr_T.NonReachRoot;
    const free_pool: *SBAResized_T.Pool_T = @alignCast(@ptrCast(&sba_allocator.top.?.bytes.?[0]));
    const unsed_frame: []u8 = free_pool.bytes.?;
    try full_alloc(SBAResized_T, &sba_allocator);
    const new_frame: []u8 = free_pool.bytes.?;
    if(@intFromPtr(new_frame.ptr) == @intFromPtr(unsed_frame.ptr)) return TestResizedErr_T.NonNewFrame;
}
