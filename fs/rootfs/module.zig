// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Kernel Arch Infos
const target_T: type = @import("root").cpu.Arch;

// kernel Modules Types
const Mod_T: type = @import("root").interfaces.module.types.Mod_T;
const ModErr_T: type = @import("root").interfaces.module.types.ModErr_T;
const ModuleDescription_T: type = @import("root").interfaces.module.types.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = @import("root").interfaces.module.types.ModuleDescriptionTarget_T;

// Kernel FS Types
const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const rootfs_mount = &@import("core.zig").rootfs_mount;
const rootfs_umount = &@import("core.zig").rootfs_umount;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .name = "ke_m_rootfs",
    .load = .linkable,
    .init = &init,
    .type = .{
        .filesystem = .{
            .compile = "/"
        }
    },
    .arch = &[_]ModuleDescriptionTarget_T {
        .x86,
        .x86_64,
        .arm,
        .avr,
    },
};

const rootfsMod: *const Mod_T = &Mod_T {
    .name = "ke_m_rootfs",
    .desc = "Core Kernel Root Filesystem",
    .author = "Linuxperoxo",
    .version = "1.0-1",
    .type = .filesystem,
    .init = &init,
    .exit = &exit,
    .private = @constCast(&@import("root").interfaces.fs.Fs_T {
        .name = "ke_m_rootfs",
        .flags = .R,
        .mount = rootfs_mount,
        .unmount = rootfs_umount,
    }),
};

fn init() ModErr_T!void {
    @call(.never_inline, &@import("root").interfaces.module.fun.inmod, .{
        rootfsMod
    }) catch |err| {
        return err;
    };
}

fn exit() ModErr_T!void {
    @call(.never_inline, &@import("root").interfaces.module.fun.rmmod, .{
        rootfsMod
    }) catch |err| {
        return err;
    };
}
