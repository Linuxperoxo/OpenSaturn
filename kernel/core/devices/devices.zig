// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const main: type = @import("main.zig");
const ops: type = @import("ops.zig");

pub const Major_T: type = types.Major_T;
pub const Minor_T: type = types.Minor_T;
pub const Dev_T: type = types.Dev_T;
pub const DevOps_T: type = types.DevOps_T;
pub const DevType_T: type = types.DevType_T;

pub const dev_minor_add = main.dev_minor_add;
pub const dev_minor_rm = main.dev_minor_rm;
pub const next_major = main.next_major;
pub const valid_major = main.valid_major;
pub const valid_minor = main.valid_minor;
pub const dev_add = main.dev_add;
pub const dev_rm = main.dev_rm;

pub const write = ops.write;
pub const read = ops.read;
pub const ioctl = ops.ioctl;
pub const mount = ops.mount;
pub const umount = ops.umount;
pub const open = ops.open;
pub const close = ops.close;

pub inline fn new_dev(dtype: DevType_T, dops: *const DevOps_T) Dev_T {
    return Dev_T {
        .type = dtype,
        .ops = dops,
        .minor = null,
        .flags = .{
            .control = .{
                .minor = 0,
                .max = 0,
            },
            .internal = .{
                .total = 0,
            },
        },
    };
}
