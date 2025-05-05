// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devfs.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const drivers: type = @import("root").drivers;
const module: type = @import("root").module;
const device: type = @import("root").devices;

pub const DeviceFileType: type = enum(u1) {
    char,
    block,
};

pub const DeviceFilesystem: type = struct {
    device: device.DeviceInterface,
    type: DeviceFileType,
};
