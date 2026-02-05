// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const devices: type = @import("root").core.devices;

pub const Major_T: type = devices.Major_T;
pub const Minor_T: type = devices.Minor_T;
pub const Dev_T: type = devices.Dev_T;
pub const DevOps_T: type = devices.DevOps_T;
pub const Devdevices_T: type = devices.DevOps_T;
pub const DevType_T: type = devices.DevType_T;

pub const dev_minor_add = devices.dev_minor_add;
pub const dev_minor_rm = devices.dev_minor_rm;
pub const next_major = devices.next_major;
pub const valid_major = devices.valid_major;
pub const valid_minor = devices.valid_minor;
pub const dev_add = devices.dev_add;
pub const dev_rm = devices.dev_rm;
pub const dev_info = devices.dev_info;

pub const write = devices.write;
pub const read = devices.read;
pub const ioctl = devices.ioctl;
pub const mount = devices.mount;
pub const umount = devices.umount;
pub const open = devices.open;
pub const close = devices.close;

pub const new_dev = devices.new_dev;
