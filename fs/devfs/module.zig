// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("root").interfaces.module.Mod_T;
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;
const ModuleDescription_T: type = @import("root").interfaces.module.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = @import("root").interfaces.module.ModuleDescriptionTarget_T;

const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const inmod = @import("root").interfaces.module.inmod;
const rmmod = @import("root").interfaces.module.rmmod;

const devfs_mount = &@import("main.zig").devfs_mount;
const devfs_umount = &@import("main.zig").devfs_umount;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .name = "ke_m_devfs",
    .load = .linkable,
    .init = &init,
    .deps = &[_][]const u8{
        "ke_m_rootfs",
    },
    .type = .{
        .filesystem = .{
            .compile = "/dev"
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
        &devfs
    });
}

fn exit() ModErr_T!void {
    return @call(.never_inline, rmmod, .{
        &devfs
    });
}
