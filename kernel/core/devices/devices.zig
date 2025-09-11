// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const fun: type = @import("fun.zig");
pub const types: type = struct {
    pub const MinorNum_T: type = @import("types.zig").MinorNum_T;
    pub const Dev_T: type = @import("types.zig").Dev_T;
    pub const DevErr_T: type = @import("types.zig").DevErr_T;
};

