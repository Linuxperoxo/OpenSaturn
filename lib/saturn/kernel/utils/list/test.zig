// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Teste Info ===
//
// OpenSaturn: 0.3.0
// OS: Gentoo Linux x86_64
// Zig: 0.15.2
// Tester: Linuxperoxo
// Status: OK

const std: type = @import("std");
const list: type = @import("list.zig");
const sba: type = @import("test/sba.zig");
const S: type = struct {
    f0: usize,
    f1: usize,
};

var allocator = sba.buildByteAllocator(null, .{}) {};

test "List All Tests" {
    const List_T: type = list.BuildList(S);
    var test_list = List_T {};
    try test_list.init(&allocator);
    for(0..128) |i| {
        try test_list.push_in_list(&allocator, .{
            .f0 = i,
            .f1 = i,
        });
        const found = try test_list.access_by_index(i);
        if(found.f0 != i) return error.PushedInDiferentIndex;
    }
    for(0..128) |i| {
        const iterator = try test_list.iterator();
        if(iterator.f0 != i) return error.IteratorDiferentData;
    }
    r: {
        _ = test_list.iterator() catch |err| switch(err) {
            @TypeOf(test_list).ListErr_T.EndOfIterator => break :r {},
            else => {},
        };
        return error.IteratorIndexOutBounds;
    }
    for(0..128) |i| {
        if(try test_list.iterator_index() != i) return error.IteratorIndexFailed;
        const iterator = try test_list.iterator();
        if(iterator.f0 != i) return error.ReinteratorDiferentData;
    }
    for(0..126) |i| {
        var found = try test_list.access_by_index(0);
        if(found.f0 != i) return error.DiferentDataInIndex;
        try test_list.drop_on_list(
            0,
            &allocator,
        );
        found = try test_list.access_by_index(0);
        if(found.f0 != i + 1) return error.DiferentDataInIndex;
    }
    try test_list.put_in_index(0, .{ .f0 = 0, .f1 = 0 }, &allocator);
    try test_list.put_in_index(1, .{ .f0 = 1, .f1 = 1 }, &allocator);
    try test_list.put_in_index(3, .{ .f0 = 3, .f1 = 3 }, &allocator);
    if(test_list.access_by_index(0)) |found| {
        if(found.f0 != 0) return error.DiferentDataIndex;
    } else |err| {
        return err;
    }
    if(test_list.access_by_index(1)) |found| {
        if(found.f0 != 1) return error.DiferentDataIndex;
    } else |err| {
        return err;
    }
    if(test_list.access_by_index(2)) |found| {
        if(found.f0 != 126) return error.DiferentDataIndex;
    } else |err| {
        return err;
    }
    if(test_list.access_by_index(3)) |found| {
        if(found.f0 != 3) return error.DiferentDataIndex;
    } else |err| {
        return err;
    }
    if(test_list.access_by_index(4)) |found| {
        if(found.f0 != 127) return error.DiferentDataIndex;
    } else |err| {
        return err;
    }
    if(test_list.how_many_nodes() != try test_list.last_index() + 1) return error.HowManyNodesError;
    test_list.deinit(&allocator) catch return error.DeinitFailed;
    if(test_list.is_initialized()) return error.AllowAfterDeinit;
    if(test_list.private != null) return error.PrivateIsNotNull;
}
