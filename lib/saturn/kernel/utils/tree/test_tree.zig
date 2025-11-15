// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test_tree.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const std: type = @import("std");
const tree: type = @import("tree.zig");
const sba: type = @import("sba_for_test.zig");

const Tree_T: type = tree.TreeBuild(usize);
const buildByteAllocator = sba.buildByteAllocator;
const AllocatorErr_T: type = Allocator_T.err_T;
const Allocator_T: type = buildByteAllocator(
    null,
    .{
        .resize = true,
    },
);
const TestErr_T: type = error {
    NodeExisteButNotFound,
    UndefinedAction,
};

var allocator: Allocator_T = .{};

test "Tree Put Test" {
    var bin_tree: Tree_T = .{};
    for(2..128) |i| {
        const id = if(i % 2 == 0) i else i - 2;
        try bin_tree.put_in_tree(id, i, &allocator);
        if(try bin_tree.search_in_tree(
                id
        ) != i) return TestErr_T.NodeExisteButNotFound;
    }
}

test "Tree Drop Test" {
    // para garantir funcionamento, a arvore e montada e desmontada
    // na mao
    var bin_tree: Tree_T = .{};
    try bin_tree.put_in_tree(0, 0, &allocator);
    try bin_tree.put_in_tree(6, 6, &allocator);
    try bin_tree.put_in_tree(7, 7, &allocator);
    try bin_tree.put_in_tree(5, 5, &allocator);
    try bin_tree.put_in_tree(4, 4, &allocator);
    try bin_tree.put_in_tree(3, 3, &allocator);
    try bin_tree.drop_in_tree(6, &allocator);
    if(bin_tree.root.?.right.?.id != 5 or
        bin_tree.root.?.right.?.left.?.id != 4 or
        bin_tree.root.?.right.?.right.?.id.? != 7) return TestErr_T.UndefinedAction;
    const search_ret = bin_tree.search_in_tree(6);
    if(search_ret) |_| return TestErr_T.UndefinedAction else |_|
    try bin_tree.drop_in_tree(7, &allocator);
    if(bin_tree.root.?.right.?.right != null) return TestErr_T.UndefinedAction;
    try bin_tree.drop_in_tree(4, &allocator);
    if(bin_tree.root.?.right.?.left.?.id.? != 3) return TestErr_T.UndefinedAction;
    try bin_tree.drop_in_tree(5, &allocator);
    if(bin_tree.root.?.right.?.id.? != 3) return TestErr_T.UndefinedAction;
    try bin_tree.drop_in_tree(0, &allocator);
    if(bin_tree.root.?.id.? != 3) return TestErr_T.UndefinedAction;
    try bin_tree.drop_in_tree(3, &allocator);
    if(bin_tree.root != null) return TestErr_T.UndefinedAction;
}
