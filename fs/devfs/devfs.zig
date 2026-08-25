// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: devfs.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const ops: type = @import("ops.zig");
const module: type = @import("root").interfaces.module;
const fs: type = @import("root").interfaces.fs;
const vfs: type = @import("root").interfaces.vfs;
const dfs: type = @import("fs.zig");
const libs: type = @import("libs.zig");

const Mod: type = module.Mod;
const ModType: type = module.ModType;
const ModControlFlags: type = module.ModControlFlags;
const ModErr: type = module.ModErr;
const ModuleDescription: type = module.ModuleDescription;
const ModuleDescriptionTarget: type = module.ModuleDescriptionTarget;
const ModuleDescriptionLibMine: type = module.ModuleDescriptionLibMine;
const ModuleDescriptionLibOut: type = module.ModuleDescriptionLibOut;

pub const createDeviceNode = ops.createDeviceNode;

pub const __SaturnModuleDescription__: ModuleDescription = .{
    .mod = &devfs,
    .panic = true,
    .load = .linkable,
    .insf = .{
        .anon = 0,
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
            ModuleDescriptionLibMine {
                .name = "devfs-operations",
                .stable = 0,
                .current = 0,
                .whitelist = null,
                .m_types = &[_]ModType {
                    .driver,
                    .filesystem,
                },
                .versions = &[_]ModuleDescriptionLibMine.Version {
                    ModuleDescriptionLibMine.Version {
                        .tag = "1.0.0",
                        .lib = libs.devfs_operations_1_0_0,
                        .flags = .{
                            .enable = 1,
                        },
                    },
                },
                .flags = .{
                    .enable = 1,
                    .whitelist = 0,
                },
            },
        },
        .outside = null,
    },
};

pub const devfs: Mod = .{
    .name = "ke_m_devfs",
    .desc = "Core Kernel Devices Filesystem",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .license = .gpl2_only,
    .type = .filesystem,
    .deps = &[_][]const u8{
        "ke_m_rootfs",
    },
    .init = &init,
    .exit = &exit,
};

fn init() anyerror!void {
    try dfs.devfs.regfs(.{
        .anon = 0,
        .nomount = 0,
        .noumount = 1,
        .readonly = 0,
    });

    vfs.touch("/dev") catch |err| switch(err) {
        vfs.VfsErr.NoNFound => {
            try vfs.mkdir("/", "dev", 0, 0, .{
                .owner = vfs.r | vfs.w,
                .group = vfs.r,
                .other = vfs.r,
            });
        },
        else => return err,
    };

    errdefer dfs.devfs.unregfs() catch {};

    try vfs.mount("devfs", "/dev", "devfs");

    try dfs.devfs.updfs(.{
        .anon = 1,
        .nomount = 0,
        .noumount = 1,
        .readonly = 0,
    });
}

fn exit() anyerror!void {
    unreachable;
}
