// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: listeners.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const pci: type = if(!builtin.is_test) @import("root").kernel.io.pci else @import("test/types.zig");
const tree: type = if(!builtin.is_test) @import("root").kernel.utils.tree else @import("test/tree.zig");

const PCIPhysIo_T: type = pci.PCIPhysIo_T;

pub var listeners_tree: tree.TreeBuild(*types.PhysIo_T) = .{};

inline fn physio_tree_id(bus: u8, device: u5, function: u3) usize {
    return
        (@as(usize, bus) << 8) |
        (@as(usize, device) << 3) |
        (@as(usize, function) << 0);
}

pub fn physio_listen(phys: *types.PhysIo_T) types.PhysIoErr_T!void {
    listeners_tree.put_in_tree(
        physio_tree_id(phys.device.bus, phys.device.device, phys.device.function),
        phys,
        &allocator.sba.allocator
    ) catch |err| switch(err) {
        @TypeOf(listeners_tree).TreeErr_T.Collision => return types.PhysIoErr_T.ListenerCollision,
        else => return types.PhysIoErr_T.InternalError,
    };
}

pub fn physio_listen_drop(phys: *types.PhysIo_T) types.PhysIoErr_T!void {
    listeners_tree.drop_in_tree(
        physio_tree_id(phys.device.bus, phys.device.device, phys.device.function),
        &allocator.sba.allocator
    ) catch |err| switch(err) {
        @TypeOf(listeners_tree).TreeErr_T.NoNFound => return types.PhysIoErr_T.NoNListener,
        else => return types.PhysIoErr_T.InternalError,
    };
}

pub fn physio_listener_search(bus: u8, device: u5, function: u3) types.PhysIoErr_T!*types.PhysIo_T {
    return listeners_tree.search_in_tree(
        physio_tree_id(bus, device, function)
    ) catch types.PhysIoErr_T.NoNListener;
}
