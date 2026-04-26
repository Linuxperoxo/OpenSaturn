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

const Mod_T: type = module.Mod_T;
const ModControlFlags_T: type = module.ModControlFlags_T;
const ModErr_T: type = module.ModErr_T;
const ModuleDescription_T: type = module.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = module.ModuleDescriptionTarget_T;
const ModuleDescriptionLibMine_T: type = module.ModuleDescriptionLibMine_T;
const ModuleDescriptionLibOut_T: type = module.ModuleDescriptionLibOut_T;

pub const create_device_node = ops.create_device_node;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .mod = &devfs,
    .panic = true,
    .load = .linkable,
    .insf = .{
        .anon = 0,
        .init = 1,
        .exit = 0,
        .remove = 0,
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
        .mines = &[_]module.ModuleDescriptionLibMine_T {
            module.ModuleDescriptionLibMine_T {
                .name = "devfs-operations",
                .stable = 0,
                .current = 0,
                .whitelist = null,
                .m_types = &[_]module.ModType_T {
                    .driver,
                    .filesystem,
                },
                .versions = &[_]module.ModuleDescriptionLibMine_T.Version_T {
                    module.ModuleDescriptionLibMine_T.Version_T {
                        .tag = "1.0.0",
                        .lib = @field(libs, "devfs-operations-1.0.0"),
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

pub const devfs: Mod_T = .{
    .name = "ke_m_devfs",
    .desc = "Core Kernel Devices Filesystem",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .license = .GPL2_only,
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
        vfs.VfsErr_T.NoNFound => {
            try vfs.mkdir("/", "dev", 0, 0, .{
                .owner = vfs.R | vfs.W,
                .group = vfs.R,
                .other = vfs.R,
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
