// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const drivers: type = @import("root").drivers;

pub const DeviceInterface: type = struct {
    deviceName: [:0]const u8,
    deviceDriver: drivers.DriverInterface,
};
