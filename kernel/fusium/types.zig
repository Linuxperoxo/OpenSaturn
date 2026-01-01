// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").interfaces.arch;

pub const FusiumDescriptionTarget_T: type = arch.Target_T;

pub const FusiumDescription_T: type = struct {
    name: []const u8,
    author: []const u8,
    contributors: ?[]const[]const u8 = null,
    description: ?[]const u8 = null,
    fusioner: type,
    init: ?*const fn() anyerror!void,
    arch: []const arch.Target_T,
    flags: packed struct {
        blocked: u1,
    },
};
