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

const rootfs_mount = &@import("management.zig").rootfs_mount;
const rootfs_umount = &@import("management.zig").rootfs_umount;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .name = "ke_m_rootfs",
    .load = .linkable,
    .init = &init,
    .after = &after,
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
    .flags = .{
        .call = .{
            .handler = 1,
            .after = 1,
        },
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
    .after = null,
    .exit = &exit,
    .private = .{
        .filesystem = .{
            .name = "rootfs",
            .flags = .R,
            .mount = rootfs_mount,
            .unmount = rootfs_umount,
        },
    },
    .flags = .{
        .control = .{
            .anon = 0,
            .call = .{
                .exit = 0,
                .remove = 0,
                .after = 0,
                .init = 0,
            },
        },
        .internal = .{
            .installed = 0,
            .removed = 0,
            .collision = .{
                .name = 0,
                .pointer = 0,
            },
            .call = .{
                .init = 0,
                .exit = 0,
                .after = 0,
            },
            .fault = .{
                .call = .{
                    .init = 0,
                    .after = 0,
                    .exit = 0,
                },
                .remove = 0,
            },
        },
    },
};

fn init() ModErr_T!void {
    return @call(.never_inline, inmod, .{
        &rootfs
    });
}

fn after() ModErr_T!void {
    rootfs.flags.control.anon = 1;
}

fn exit() ModErr_T!void {
    return @call(.never_inline, rmmod, .{
        &rootfs
    });
}
