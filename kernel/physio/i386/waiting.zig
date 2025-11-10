// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: waiting.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const pci: type = if(!builtin.is_test) @import("root").kernel.io.pci else @import("test/types.zig");
const tree: type = if(!builtin.is_test) @import("root").kernel.utils.tree else @import("test/tree.zig");
const fn_T: type = fn(*types.PhysIo_T) if(!builtin.is_test) void else usize;

pub var waiting_tree: tree.TreeBuild(*const fn_T) = .{};

inline fn make_id(class: u8, vendor: u16) usize {
    return (vendor << 8) | class;
}

pub fn physio_wait_by(class: u8, vendor: u16, event: *const fn_T) types.PhysIoErr_T!void {
    waiting_tree.put_in_tree(
        make_id(class, vendor), event, &allocator.sba.allocator
    ) catch |err| switch(err) {
        @TypeOf(waiting_tree).TreeErr_T.Collision => return types.PhysIoErr_T.AlwaysWaiting,
        else => return types.PhysIoErr_T.InternalError,
    };
}

pub fn physio_wait_drop(class: u8, vendor: u16) types.PhysIoErr_T!void {
    waiting_tree.drop_in_tree(
        make_id(class, vendor), &allocator.sba.allocator
    ) catch |err| switch(err) {
        @TypeOf(waiting_tree).TreeErr_T.NoNFound => return types.PhysIoErr_T.NoNWaiting,
        else => return types.PhysIoErr_T.InternalError,
    };
}

pub fn physio_wait_search(class: u8, vendor: u16) types.PhysIoErr_T!*const fn_T {
    return waiting_tree.search_in_tree(
        make_id(class, vendor)
    ) catch types.PhysIoErr_T.NoNListener;
}
