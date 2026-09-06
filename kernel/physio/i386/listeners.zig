// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: listeners.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const tree: type = @import("root").lib.kernel.binary_tree;

pub var listeners_tree: tree.binaryTree(*types.PhysIo) = .{};

inline fn physioTreeId(bus: u8, device: u5, function: u3) usize {
    return
        (@as(usize, bus) << 8) |
        (@as(usize, device) << 3) |
        (@as(usize, function) << 0);
}

pub fn physioListen(phys: *types.PhysIo) types.PhysIoErr!void {
    listeners_tree.putInTree(
        physioTreeId(phys.device.bus, phys.device.device, phys.device.function),
        phys,
        &allocator.sba.allocator
    ) catch |err| switch(err) {
        @TypeOf(listeners_tree).TreeErr.Collision => return types.PhysIoErr.ListenerCollision,
        else => return types.PhysIoErr.InternalError,
    };
}

pub fn physioListenDrop(phys: *types.PhysIo) types.PhysIoErr!void {
    listeners_tree.dropInTree(
        physioTreeId(phys.device.bus, phys.device.device, phys.device.function),
        &allocator.sba.allocator
    ) catch |err| switch(err) {
        @TypeOf(listeners_tree).TreeErr.NoNFound => return types.PhysIoErr.NoNListener,
        else => return types.PhysIoErr.InternalError,
    };
}

pub fn physioListenerSearch(bus: u8, device: u5, function: u3) types.PhysIoErr!*types.PhysIo {
    return listeners_tree.searchInTree(
        physioTreeId(bus, device, function)
    ) catch types.PhysIoErr.NoNListener;
}
