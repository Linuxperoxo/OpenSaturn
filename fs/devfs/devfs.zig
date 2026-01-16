// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devfs.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const ops: type = @import("ops.zig");
const module: type = @import("root").interfaces.module;

const Mod_T: type = module.Mod_T;
const ModErr_T: type = module.ModErr_T;
const ModuleDescription_T: type = module.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = module.ModuleDescriptionTarget_T;
const ModuleDescriptionLibMine_T: type = module.ModuleDescriptionLibMine_T;
const ModuleDescriptionLibOut_T: type = module.ModuleDescriptionLibOut_T;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .name = "ke_m_devfs",
    .load = .linkable,
    .init = &init,
    .after = &opaque {
        // fn chamada apos mount
        pub fn after() anyerror!void {
            if(devfs.flags.check_op_status(.init) == 0) {
                // klog()
            }
            devfs.flags.control.anon = 1;
        }
    }.after,
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
            .mount = ops.devfs_mount,
            .umount = ops.devfs_umount,
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

fn init() anyerror!void {
    return @call(.never_inline, module.inmod, .{
        &devfs
    });
}

fn exit() anyerror!void {
    return @call(.never_inline, module.rmmod, .{
        &devfs
    });
}
