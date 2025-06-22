// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Mod_T: type = @import("root").interfaces.module.Mod_T;

const ModS_T: type = enum(u2) {
    uninitialized,
    running,
    undefined,
};

const moduleRoot: struct {
    next: ?*@This(),
    prev: ?*@This(),
    this: ?*Mod_T,
    status: ModS_T,
} = .{
    .next = null,
    .prev = null,
    .module = null,
    .status = .undefined,
};

pub fn inmod(
    mod: Mod_T,
) usize {
    _ = mod;
}

pub fn rmmod(
    name: []const u8
) usize {
    _ = name;
}
