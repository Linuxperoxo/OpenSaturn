// ┌────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: fs.zig     │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const fs: type = @import("root").interfaces.fs;
const ops: type = @import("ops.zig");

pub var rootfs: fs.Fs = .{
    .name = "rootfs",
    .mount = ops.rootfsMount,
    .umount = ops.rootfsUmount,
};
