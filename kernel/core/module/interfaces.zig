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

pub const LinkModInKernel: type = struct {
    init: fn() anyerror!usize,
};
