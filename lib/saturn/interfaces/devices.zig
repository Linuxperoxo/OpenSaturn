// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").core.devices.interfaces;

pub const Dev_T: type = interfaces.Dev_T;

pub const register_dev = interfaces.register_dev;
pub const unregister_dev = interfaces.unregister_dev;
//pub const alloc: fn() void;
//pub const free: fn() void;
