// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;

pub const Node_T: type = struct {
    next: ?*@This(),
    prev: ?*@This(),
    module: ?interfaces.module.ModuleDescription_T,
    flags: packed struct(u8) {
        fixed: u1,
        reserved: u7 = 0,
    },
};

pub const Direct_T: type = enum {
    left,
    right,
};
