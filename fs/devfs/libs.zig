// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: libs.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const ops: type = @import("ops.zig");

pub const @"devfs-operations-1.0.0": type = opaque {
    pub const create_device_node = ops.create_device_node;
    pub const unlink_device_node = ops.unlink_device_node;
};
