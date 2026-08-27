// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: rootfs.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const c: type = @import("root").lib.kernel.c;
const module: type = @import("root").interfaces.module;
const fs: type = @import("root").interfaces.fs;
const vfs: type = @import("root").interfaces.vfs;
const rfs: type = @import("fs.zig");

const Mod: type = module.Mod;
const ModControlFlags: type = module.ModControlFlags;
const ModErr: type = module.ModErr;
const ModType: type = module.ModType;
const ModuleDescription: type = module.ModuleDescription;
const ModuleDescriptionTarget: type = module.ModuleDescriptionTarget;
const ModuleDescriptionLibMine: type = module.ModuleDescriptionLibMine;
const ModuleDescriptionLibOut: type = module.ModuleDescriptionLibOut;

pub const __SaturnModuleDescription__: ModuleDescription = .{
    .mod = &rootfs,
    .load = .linkable,
    .panic = true,
    .insf = .{
        .anon = 1,
        .init = 1,
        .exit = 0,
        .remove = 0,
    },
    .arch = &[_]ModuleDescriptionTarget {
        .i386,
        .amd64,
        .arm,
        .avr,
        .riscv64,
        .xtensa,
    },
    .libs = .{
        .mines = &[_]ModuleDescriptionLibMine {
            .{
                .name = "inode-utils",
                .whitelist = null,
                .m_types = &[_]ModType {
                    .filesystem,
                },
                .current = 0,
                .stable = 0,
                .versions = &[_]ModuleDescriptionLibMine.Version {
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
        .outside = &[_]ModuleDescriptionLibOut {
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

pub const rootfs: Mod = .{
    .name = "ke_m_rootfs",
    .desc = "Core Kernel Root Filesystem",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .license = .gpl2_only,
    .type = .filesystem,
    .init = &init,
    .exit = &exit,
};

fn init() anyerror!void {
    try rfs.rootfs.regfs(.{
        .anon = 0,
        .nomount = 1,
        .noumount = 1,
        .readonly = 0,
    });

    errdefer rfs.rootfs.unregfs() catch {};

    try vfs.mount("rootfs", "/", rfs.rootfs.name);

    try rfs.rootfs.updfs(.{
        .anon = 1,
        .nomount = 1,
        .noumount = 1,
        .readonly = 0,
    });
}

fn exit() anyerror!void {
    unreachable;
}
