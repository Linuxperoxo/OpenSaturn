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
    init: *fn() anyerror!void,
    exit: *fn() anyerror!void,
};

pub const LinkModInKernel: type = struct {
    init: fn() anyerror!void,
};

// NOTE: TMP
pub const alloc = @import("root").memory.kmalloc;
pub const free = @import("root").memory.kfree;
