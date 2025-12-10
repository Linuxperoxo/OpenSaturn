// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// kernel Modules Types
const Mod_T: type = @import("root").interfaces.module.Mod_T;
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;
const ModuleDescription_T: type = @import("root").interfaces.module.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = @import("root").interfaces.module.ModuleDescriptionTarget_T;

// Kernel FS Types
const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const inmod = @import("root").interfaces.module.inmod;
const rmmod = @import("root").interfaces.module.rmmod;

const rootfs_mount = &@import("main.zig").rootfs_mount;
const rootfs_umount = &@import("main.zig").rootfs_umount;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .name = "ke_m_rootfs",
    .load = .linkable,
    .init = &init,
    .deps = null,
    .type = .{
        .filesystem = .{
            .compile = "/"
        }
    },
    .arch = &[_]ModuleDescriptionTarget_T {
        .i386,
        .amd64,
        .arm,
        .avr,
        .riscv64,
        .xtensa,
    },
};

var rootfs: Mod_T = .{
    .name = __SaturnModuleDescription__.name,
    .desc = "Core Kernel Root Filesystem",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .deps = null,
    .license = .{
        .know = .GPL2_only,
    },
    .type = .filesystem,
    .init = &init,
    .exit = &exit,
    .private = .{
        .filesystem = .{
            .name = "rootfs",
            .mount = rootfs_mount,
            .umount = rootfs_umount,
            .flags = .{
                .control = .{
                    .nomount = 0,
                    .noumount = 1,
                    .readonly = 0,
                    .anon = 0,
                },
                .internal = .{
                    .mounted = 0,
                    .registered = 0,
                    .collision = .{
                        .name = 0,
                        .pointer = 0,
                    },
                    .fault = .{
                        .mount = 0,
                        .umount = 0,
                        .write = 0,
                    },
                },
            },
        },
    },
};

fn init() ModErr_T!void {
    return @call(.never_inline, inmod, .{
        &rootfs
    });
}

fn exit() ModErr_T!void {
    return @call(.never_inline, rmmod, .{
        &rootfs
    });
}
