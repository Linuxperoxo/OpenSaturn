// ┌────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: fs.zig     │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const fs: type = @import("root").interfaces.fs;
const ops: type = @import("ops.zig");

pub var rootfs: fs.Fs_T = .{
    .name = "rootfs",
    .mount = ops.rootfs_mount,
    .umount = ops.rootfs_umount,
    .flags = .{
        .control = .{
            .nomount = 0,
            .noumount = 1,
            .readonly = 0,
            .anon = 0,
        },
    },
};
