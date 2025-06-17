// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const rootfs: Fs_T = .{
    .name = "rootfs",
    .flags = .{
        .write = 0,
    },
    .mod = .{
        .name = "rootfs",
        .desc = "Core Kernel Root Filesystem",
        .author = "Linuxperoxo",
        .version = "1.0-1",
        .type = .filesystem,
        .init = &init,
        .exit = &exit,
    },
    .ops = .{
        .mount = .{ 
            .nodev = &rootfs_mount,
        },
        .umount = &rootfs_umount,
    },
};

fn init() u32 {
    @call(
        .never_inline,
        &@import("root").interfaces.fs.registerfs,
        .{
            rootfs
        }
    );
}

fn exit() u32 {
    @call(
        .never_inline,
        &@import("root").interfaces.fs.unregisterfs,
        .{
            rootfs.name
        }
    );
}
