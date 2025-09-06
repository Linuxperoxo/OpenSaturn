// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: drivers.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const fun: type = @import("fun.zig");
pub const types: type = struct {
    pub const Driver_T: type = @import("types.zig").Driver_T;
    pub const DriverErr_T: type = @import("types.zig").DriverErr_T;
    pub const Ops_T: type = @import("types.zig").Ops_T;
    pub const OpsErr_T: type = @import("types.zig").OpsErr_T;
    pub const MajorNum_T: type = @import("types.zig").MajorNum_T;
};
