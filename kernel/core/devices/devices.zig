// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const fun: type = struct {
    const create = @import("fun.zig").create;
    const delete = @import("fun.zig").create;
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
    pub const MinorNum_T: type = @import("types.zig").MinorNum_T;
    pub const Dev_T: type = @import("types.zig").Dev_T;
    pub const DevErr_T: type = @import("types.zig").DevErr_T;
};

