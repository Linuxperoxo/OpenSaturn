// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").interfaces.arch;

pub const FusiumDescription: type = struct {
    pub const Target: type = arch.Target;

    pub const Order: type = enum {
        // before: chama init antes dos modulos
        // after: chama init depois dos modulos
        before,
        after,
    };

    name: []const u8,
    author: []const u8,
    order: Order,
    contributors: ?[]const[]const u8 = null,
    description: ?[]const u8 = null,
    fusioner: type,
    init: ?*const fn() anyerror!void,
    arch: []const Target,
    flags: packed struct {
        blocked: u1,
    },
};
