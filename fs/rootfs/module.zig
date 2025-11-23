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

const rootfs_mount = &@import("management.zig").rootfs_mount;
const rootfs_umount = &@import("management.zig").rootfs_umount;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .name = "ke_m_rootfs",
    .load = .unlinkable,
    .init = &init,
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
    .name = "ke_m_rootfs",
    .desc = "Core Kernel Root Filesystem",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .license = .{
        .know = .GPL2_only,
    },
    .type = .filesystem,
    .init = &init,
    .exit = &exit,
    .private = @constCast(&Fs_T {
        .name = "rootfs",
        .flags = .R,
        .mount = rootfs_mount,
        .unmount = rootfs_umount,
    }),
};

fn init() ModErr_T!void {
    @call(.never_inline, &@import("root").interfaces.module.inmod, .{
        rootfsMod
    }) catch |err| {
        return err;
    };
}

fn exit() ModErr_T!void {
    @call(.never_inline, &@import("root").interfaces.module.rmmod, .{
        rootfsMod
    }) catch |err| {
        return err;
    };
}
