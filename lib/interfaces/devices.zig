// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const devices: type = @import("root").core.devices;

pub const Major: type = devices.Major_T;
pub const Minor: type = devices.Minor_T;
pub const Dev: type = devices.Dev_T;
pub const DevErr: type = devices.DevErr_T;
pub const DevOps: type = devices.DevOps_T;
pub const Devdevices: type = devices.DevOps_T;
pub const DevType: type = devices.DevType_T;

pub const deviceAddMinor = devices.dev_minor_add;
pub const deviceRmMinor = devices.dev_minor_rm;
pub const nextMajorForDevice = devices.next_major;
pub const isAValidMajor = devices.valid_major;
pub const isAValidMinor = devices.valid_minor;
pub const addDevice = devices.dev_add;
pub const rmDevice = devices.dev_rm;
pub const deviceInfo = devices.dev_info;

pub const write = devices.write;
pub const read = devices.read;
pub const ioctl = devices.ioctl;
pub const mount = devices.mount;
pub const umount = devices.umount;
pub const open = devices.open;
pub const close = devices.close;
