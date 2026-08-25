// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const devices: type = @import("root").core.devices;

pub const Major: type = devices.Major;
pub const Minor: type = devices.Minor;
pub const Dev: type = devices.Dev;
pub const DevErr: type = devices.DevErr;
pub const DevOps: type = devices.DevOps;
pub const Devdevices: type = devices.DevOps;
pub const DevType: type = devices.DevType;

pub const deviceAddMinor = devices.devMinorAdd;
pub const deviceRmMinor = devices.devMinorRm;
pub const nextMajorForDevice = devices.nextMajor;
pub const isAValidMajor = devices.validMajor;
pub const isAValidMinor = devices.validMinor;
pub const addDevice = devices.devAdd;
pub const rmDevice = devices.devRm;
pub const deviceInfo = devices.devInfo;

pub const write = devices.write;
pub const read = devices.read;
pub const ioctl = devices.ioctl;
pub const mount = devices.mount;
pub const umount = devices.umount;
pub const open = devices.open;
pub const close = devices.close;
