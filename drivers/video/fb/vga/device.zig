// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: device.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const devices: type = @import("root").interfaces.devices;
const ops: type = @import("ops.zig");

pub var fb_device: devices.Dev_T = .{
    .name = "fb",
    .type = .char,
    .ops = &fb_device_ops,
    .flags = .{
        .control = .{
            .minor = 0,
            .max = 0,
        },
    },
};

pub const fb_device_ops: devices.DevOps_T = .{
    .write = &ops.write,
    .read = &ops.read,
    .ioctl = &ops.ioctl,
};
