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
};

const rootfsMod: *const Mod_T = &Mod_T {
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
    .exit = &exit,
    .private = .{
        .filesystem = .{
            .name = "rootfs",
            .flags = .R,
            .mount = rootfs_mount,
            .unmount = rootfs_umount,
        },
    },
};

fn init() ModErr_T!void {
    return @call(.never_inline, inmod, .{
        rootfsMod
    });
}

fn exit() ModErr_T!void {
    return @call(.never_inline, rmmod, .{
        rootfsMod
    });
}
