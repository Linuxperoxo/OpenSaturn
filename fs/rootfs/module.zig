// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Fs_T: type = @import("root").interfaces.fs.Fs_T;

pub const __linkable__: @import("root").interfaces.module.LinkModInKernel = .{
    .init = init,
};

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
            .nodev = &@import("management.zig").rootfs_mount,
        },
        .umount = &@import("management.zig").rootfs_umount,
    },
};

fn init() anyerror!void {
    asm volatile(
        \\ movl $0xB8000, %eax
        \\ movl (%eax), $'H'
        :
        :
        :"eax"
    );
    @call(
        .never_inline,
        &@import("root").interfaces.fs.registerfs,
        .{
            rootfs
        }
    );
}

fn exit() anyerror!void {
    @call(
        .never_inline,
        &@import("root").interfaces.fs.unregisterfs,
        .{
            rootfs.name
        }
    );
}
