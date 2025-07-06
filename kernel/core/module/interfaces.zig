// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Allocator: type = @import("module.zig").memory.Allocator;

pub const Mod_T: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    type: ModType_T,
    init: *const fn() ModErr_T!void,
    exit: *const fn() ModErr_T!void,
    private: ?*anyopaque,
};

pub const ModType_T: type = enum(u2) {
    driver,
    filesystem,
    syscall,
};

pub const ModErr_T: type = error {
    IsInitialized,
    NoNInitialized,
    InternalError,
};

pub const LinkModInKernel: type = struct {
    init: *const fn() ModErr_T!void,
};
