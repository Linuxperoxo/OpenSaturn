// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: rootfs.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const c: type = @import("root").lib.utils.c;
const module: type = @import("root").interfaces.module;
const fs: type = @import("root").interfaces.fs;
const vfs: type = @import("root").interfaces.vfs;
const rfs: type = @import("fs.zig");

const Mod_T: type = module.Mod_T;
const ModControlFlags_T: type = module.ModControlFlags_T;
const ModErr_T: type = module.ModErr_T;
const ModType_T: type = module.ModType_T;
const ModuleDescription_T: type = module.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = module.ModuleDescriptionTarget_T;
const ModuleDescriptionLibMine_T: type = module.ModuleDescriptionLibMine_T;
const ModuleDescriptionLibOut_T: type = module.ModuleDescriptionLibOut_T;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .mod = &rootfs,
    .load = .linkable,
    .panic = true,
    .blacklist = &[_][]const u8 {
        "ke_m_devfs"
    },
    .arch = &[_]ModuleDescriptionTarget_T {
        .i386,
        .amd64,
        .arm,
        .avr,
        .riscv64,
        .xtensa,
    },
    .libs = .{
        .mines = &[_]ModuleDescriptionLibMine_T {
            .{
                .name = "inode-utils",
                .whitelist = null,
                .m_types = &[_]ModType_T {
                    .filesystem,
                },
                .current = 0,
                .stable = 0,
                .versions = &[_]ModuleDescriptionLibMine_T.Version_T {
                    .{
                        .lib = @import("lib/inode.zig"),
                        .tag = "0.1.0",
                        .flags = .{
                            .enable = 1,
                        },
                    },
                },
                .flags = .{
                    .whitelist = 0,
                    .enable = 1,
                },
            },
        },
        .outside = &[_]ModuleDescriptionLibOut_T {
            .{
                .lib = "inode-utils",
                .mod = "ke_m_rootfs",
                .version = .{
                    .tag = "0.1.0",
                },
                .flags = .{
                    .required = 1,
                },
            },
        },
    },
};

pub const rootfs: Mod_T = .{
    .name = "ke_m_rootfs",
    .desc = "Core Kernel Root Filesystem",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .license = .GPL2_only,
    .type = .filesystem,
    .init = &init,
    .exit = &exit,
    .control = &rootfs_control,
};

pub var rootfs_control: ModControlFlags_T = .{
    .init = 1,
    .exit = 0,
    .remove = 0,
    .anon = 0,
};

fn init() anyerror!void {
    try fs.register_fs(&rfs.rootfs);
    errdefer fs.unregister_fs(&rfs.rootfs) catch {};
    try vfs.mount("/", null, rfs.rootfs.name);
    rfs.rootfs.flags.control = .{
        .anon = 1,
        .nomount = 1,
        .noumount = 1,
        .readonly = 0,
    };
}

fn exit() anyerror!void {
    unreachable;
}
