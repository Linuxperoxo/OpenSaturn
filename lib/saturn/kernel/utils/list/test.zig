// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Teste Info ===
//
// OpenSaturn: 0.1.1
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
const TestErr_T: type = error {
    InvalidIndexAccess,
    DiferentDataInIndex,
    IteratorDiferentData,
    ReinteratorDiferentData,
    IteratorIndexOutBounds,
    PushedInDiferentIndex,
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
        if(found.f0 != i) return TestErr_T.PushedInDiferentIndex;
    }
    for(0..128) |i| {
        const iterator = try test_list.iterator();
        if(iterator.f0 != i) return TestErr_T.IteratorDiferentData;
    }
    r: {
        _ = test_list.iterator() catch |err| switch(err) {
            @TypeOf(test_list).ListErr_T.EndOfIterator => break :r {},
            else => {},
        };
        return TestErr_T.IteratorIndexOutBounds;
    }
    for(0..128) |i| {
        const iterator = try test_list.iterator();
        if(iterator.f0 != i) return TestErr_T.ReinteratorDiferentData;
    }
    for(0..127) |i| {
        var found = try test_list.access_by_index(0);
        if(found.f0 != i) return TestErr_T.DiferentDataInIndex;
        try test_list.drop_on_list(
            0,
            &allocator,
        );
        found = try test_list.access_by_index(0);
        if(found.f0 != i + 1) return TestErr_T.DiferentDataInIndex;
    }
    _ = test_list.access_by_index(0) catch |err| switch(err) {
        @TypeOf(test_list).ListErr_T.IndexOutBounds => {},
        else => return TestErr_T.InvalidIndexAccess,
    };
}
