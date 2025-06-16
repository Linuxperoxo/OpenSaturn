// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const ModType_T: type = enum(u2) {
    driver,
    filesystem,
    syscall,
};

pub const Mod_T: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    type: ModType_T,
    init: *fn() usize,
    exit: *fn() usize,
};

const ModS_T: type = enum(u2) {
    uninitialized,
    running,
    undefined,
};

const ModRoot: struct {
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

}

pub fn rmmod(
    name: []const u8
) usize {

}
