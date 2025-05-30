// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const drivers: type = @import("root").drivers;
const module: type = @import("root").module;

pub const DeviceInterface: type = struct {
    driver: *drivers.DriverInterface,
};
