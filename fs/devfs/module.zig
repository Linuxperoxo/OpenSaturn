// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("root").interfaces.module.Mod_T;
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;
const ModuleDescription_T: type = @import("root").interfaces.module.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = @import("root").interfaces.module.ModuleDescriptionTarget_T;
const ModuleDescriptionLibMine_T: type = @import("root").interfaces.module.ModuleDescriptionLibMine_T;
const ModuleDescriptionLibOut_T: type = @import("root").interfaces.module.ModuleDescriptionLibOut_T;

const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const inmod = @import("root").interfaces.module.inmod;
const rmmod = @import("root").interfaces.module.rmmod;

const devfs_mount = &@import("main.zig").devfs_mount;
const devfs_umount = &@import("main.zig").devfs_umount;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .name = "ke_m_devfs",
    .load = .linkable,
    .init = &init,
    .after = &after,
    .deps = &[_][]const u8{
        "ke_m_rootfs",
    },
    .type = .{
        .filesystem = .{
            .compile = .{
                .name = "ke_m_devfs",
                .mountpoint = "/dev",
            },
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
    .libs = .{
        .mines = null,
        .outside = null,
    },
};

var devfs: Mod_T = .{
    .name = __SaturnModuleDescription__.name,
    .desc = "Core Kernel Devices Filesystem",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .deps = __SaturnModuleDescription__.deps,
    .license = .{
        .know = .GPL2_only,
    },
    .type = .filesystem,
    .init = &init,
    .after = null,
    .exit = &exit,
    .private = .{
        .filesystem = .{
            .name = "devfs",
            .mount = devfs_mount,
            .umount = devfs_umount,
            .flags = .{
                .control = .{
                    .nomount = 0,
                    .noumount = 1,
                    .readonly = 0,
                    .anon = 0,
                },
                .internal = .{},
            },
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
                .handler = .{
                    .install = 1,
                    .remove = 1,
                },
            },
        },
        .internal = .{},
    },
};

fn init() ModErr_T!void {
    return @call(.never_inline, inmod, .{
        &devfs
    });
}

fn after() ModErr_T!void {
    if(devfs.flags.check_op_status(.init) == 0) {
        // klog()
    }
    devfs.flags.control.anon = 1;
}

fn exit() ModErr_T!void {
    return @call(.never_inline, rmmod, .{
        &devfs
    });
}
