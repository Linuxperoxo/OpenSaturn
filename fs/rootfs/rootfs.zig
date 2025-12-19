// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: rootfs.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const c: type = @import("root").kernel.utils.c;
const interfaces: type = @import("root").interfaces;
const list: type = @import("root").kernel.utils.list;

const Mod_T: type = interfaces.module.Mod_T;
const ModErr_T: type = interfaces.module.ModErr_T;
const ModuleDescription_T: type = interfaces.module.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = interfaces.module.ModuleDescriptionTarget_T;
const ModuleDescriptionLibMine_T: type = interfaces.module.ModuleDescriptionLibMine_T;
const ModuleDescriptionLibOut_T: type = interfaces.module.ModuleDescriptionLibOut_T;

const Fs_T: type = interfaces.fs.Fs_T;

const inmod = interfaces.module.inmod;
const rmmod = interfaces.module.rmmod;

const rootfs_mount = &@import("main.zig").rootfs_mount;
const rootfs_umount = &@import("main.zig").rootfs_umount;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .name = "ke_m_rootfs",
    .load = .linkable,
    .init = &init,
    .after = &opaque {
        pub fn after() anyerror!void {
            // como habilitamos no handler em flags.call.handler = 1
            // vamos chegar nessa funcao ja com o fs registrado, e o
            // e o mesmo montado
            if(!c.c_bool(rootfs.flags.internal.installed & rootfs.flags.check_op_status(.install))) {
                // panic("failed to init rootfs")
            }
            if(!c.c_bool(rootfs.private.filesystem.flags.internal.mounted & ~rootfs.private.filesystem.flags.internal.fault.mount)) {
                // panic("failed to mount rootfs")
            }
            rootfs.private.filesystem.flags.control.anon = 1;
            rootfs.flags.control.anon = 1;
        }
    }.after,
    .deps = null,
    .type = .{
        .filesystem = .{
            .compile = .{
                .name = "rootfs",
                .mountpoint = "/",
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
        .mines = &[_]ModuleDescriptionLibMine_T {
            ModuleDescriptionLibMine_T {
                .name = "inode-utils",
                .whitelist = null,
                .lib = @import("lib/inode.zig"),
                .flags = .{
                    .whitelist = 0,
                    .enable = 1,
                },
            },
        },
        .outside = &[_]ModuleDescriptionLibOut_T {
            ModuleDescriptionLibOut_T {
                .lib = "inode-utils",
                .mod = "ke_m_rootfs",
                .flags = .{
                    .required = 1,
                },
            },
        },
    },
};

pub var rootfs: Mod_T = .{
    .name = "rootfs",
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
            .mount = rootfs_mount,
            .umount = rootfs_umount,
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
                    .install = 1, // deixa o proprio inmod chamar o register_fs()
                    .remove = 0, // deixa o proprio rmmod chamar o unregister_fs()
                },
            },
        },
        .internal = .{},
    },
};

fn init() ModErr_T!void {
    @call(.never_inline, inmod, .{
        &rootfs
    }) catch unreachable;
    // aqui nao precisamos nos preocupar com registra o fs, ja que a flag rootfs.flags.control.call.handler.{install,remove}
    // ja se encarrega que chamar o register_fs e o unregister_fs quando usamos o inmod e rmmod
}

fn exit() ModErr_T!void {
    return @call(.never_inline, rmmod, .{
        &rootfs
    });
}
