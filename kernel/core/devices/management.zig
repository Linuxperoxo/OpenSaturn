// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Dev_T: type = @import("root").core.devices.interfaces.Dev_T;
const DevType_T: type = @import("root").core.devices.interfaces.DevType_T;
const DevErr_T: type = @import("root").core.devices.interfaces.DevErr_T;

pub fn register_dev(
    dev: Dev_T,
    devT: DevType_T
) DevErr_T!usize {
    _ = dev;
    _ = devT;
}

pub fn unregister_dev(
    name: []const u8
) DevErr_T!usize {
    _ = name;
}
