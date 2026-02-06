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
    .control = &devfs_control,
};

pub var devfs_control: ModControlFlags_T = .{
    .init = 1,
    .exit = 0,
    .remove = 0,
    .anon = 0,
};

fn init() anyerror!void {
    try fs.register_fs(&dfs.devfs);
    errdefer fs.unregister_fs(&dfs.devfs) catch {};
    try vfs.mount("/dev", null, "devfs");
    dfs.devfs.flags.control = .{
        .anon = 1,
        .nomount = 1,
        .noumount = 1,
        .readonly = 0,
    };
}

fn exit() anyerror!void {
    unreachable;
}
