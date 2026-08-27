// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: libs.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const ops: type = @import("ops.zig");

pub const devfs_operations_1_0_0: type = opaque {
    pub const createDeviceNode = ops.createDeviceNode;
    pub const unlinkDeviceNode = ops.unlinkDeviceNode;
};
