// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: drivers.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const fun: type = struct {
    pub const register = @import("fun.zig").register;
    pub const unregister = @import("fun.zig").unregister;
    pub const ops: type = struct {
        pub const open = @import("ops.zig").open;
        pub const close = @import("ops.zig").close;
        pub const minor = @import("ops.zig").minor;
        pub const read = @import("ops.zig").read;
        pub const write = @import("ops.zig").write;
        pub const ioctrl = @import("ops.zig").ioctrl;
    };
};
pub const types: type = struct {
    pub const Driver_T: type = @import("types.zig").Driver_T;
    pub const DriverErr_T: type = @import("types.zig").DriverErr_T;
    pub const Ops_T: type = @import("types.zig").Ops_T;
    pub const OpsErr_T: type = @import("types.zig").OpsErr_T;
    pub const MajorNum_T: type = @import("types.zig").MajorNum_T;
    pub const MinorNum_T: type = @import("types.zig").MinorNum_T;
};
