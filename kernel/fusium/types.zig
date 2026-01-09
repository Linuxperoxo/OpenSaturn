// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").interfaces.arch;

pub const FusiumDescription_T: type = struct {
    pub const Target_T: type = arch.Target_T;

    pub const Order_T: type = enum {
        // before: chama init antes dos modulos
        // after: chama init depois dos modulos
        before,
        after,
    };

    name: []const u8,
    author: []const u8,
    order: Order_T,
    contributors: ?[]const[]const u8 = null,
    description: ?[]const u8 = null,
    fusioner: type,
    init: ?*const fn() anyerror!void,
    arch: []const Target_T,
    flags: packed struct {
        blocked: u1,
    },
};
