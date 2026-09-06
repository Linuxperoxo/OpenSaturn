// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: waiting.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const tree: type = @import("root").lib.kernel.binary_tree;
const PhysIoWaitFn: type = fn(*types.PhysIo) void;

pub var waiting_tree: tree.binaryTree(*const PhysIoWaitFn) = .{};

inline fn makeId(class: u8, vendor: u16) usize {
    return (vendor << 8) | class;
}

pub fn physioWaitBy(class: u8, vendor: u16, event: *const PhysIoWaitFn) types.PhysIoErr!void {
    waiting_tree.putInTree(
        makeId(class, vendor), event, &allocator.sba.allocator
    ) catch |err| switch(err) {
        @TypeOf(waiting_tree).TreeErr.Collision => return types.PhysIoErr.AlwaysWaiting,
        else => return types.PhysIoErr.InternalError,
    };
}

pub fn physioWaitDrop(class: u8, vendor: u16) types.PhysIoErr!void {
    waiting_tree.dropInTree(
        makeId(class, vendor), &allocator.sba.allocator
    ) catch |err| switch(err) {
        @TypeOf(waiting_tree).TreeErr.NoNFound => return types.PhysIoErr.NoNWaiting,
        else => return types.PhysIoErr.InternalError,
    };
}

pub fn physioWaitSearch(class: u8, vendor: u16) types.PhysIoErr!*const PhysIoWaitFn {
    return waiting_tree.searchInTree(
        makeId(class, vendor)
    ) catch types.PhysIoErr.NoNListener;
}
