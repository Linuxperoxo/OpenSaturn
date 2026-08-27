// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const main: type = @import("main.zig");
const ops: type = @import("ops.zig");

pub const Major: type = types.Major;
pub const Minor: type = types.Minor;
pub const Dev: type = types.Dev;
pub const DevErr: type = types.DevErr;
pub const DevOps: type = types.DevOps;
pub const DevType: type = types.DevType;

pub const devMinorAdd = main.devMinorAdd;
pub const devMinorRm = main.devMinorRm;
pub const nextMajor = main.nextMajor;
pub const validMajor = main.validMajor;
pub const validMinor = main.validMinor;
pub const devAdd = main.devAdd;
pub const devRm = main.devRm;
pub const devInfo = main.devInfo;

pub const write = ops.write;
pub const read = ops.read;
pub const ioctl = ops.ioctl;
pub const mount = ops.mount;
pub const umount = ops.umount;
pub const open = ops.open;
pub const close = ops.close;
