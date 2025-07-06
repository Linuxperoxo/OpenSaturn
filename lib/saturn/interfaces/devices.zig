// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const devices: type = @import("root").core.devices;
const interfaces: type = devices.interfaces;
const management: type = devices.management;

pub const Dev_T: type = interfaces.Dev_T;
pub const DevType_T: type = interfaces.DevType_T;
pub const DevErr_T: type = interfaces.DevErr_T;

pub const register_dev: fn(Dev_T, DevType_T) DevErr_T!usize = management.register_dev;
pub const unregister_dev: fn([]const u8) DevErr_T!usize = management.unregister_dev;
//pub const alloc: fn() void;
//pub const free: fn() void;
