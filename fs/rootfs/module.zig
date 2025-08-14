// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Kernel Arch Infos
const target_T: type = @import("root").arch.target_T;

// kernel modules types
const Mod_T: type = @import("root").interfaces.module.Mod_T;
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;

// kernel fs types
const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const rootfs_mount = &@import("management.zig").rootfs_mount;
const rootfs_umount = &@import("management.zig").rootfs_umount;

pub const __linkable_module_name__: []const u8 = "ke_m_rootfs";
pub const __linkable_module_init__: *const fn() anyerror!void = &init;
pub const __linkable_module_optional__: bool = false;
pub const __linkable_module_arch__: [4]target_T = .{
    .x86,
    .x86_64,
    .arm,
    .avr,
};

const rootfsMod: *const Mod_T = &Mod_T {
    .name = "rootfs",
    .desc = "Core Kernel Root Filesystem",
    .author = "Linuxperoxo",
    .version = "1.0-1",
    .type = .filesystem,
    .init = &init,
    .exit = &exit,
    .private = @constCast(&@import("root").interfaces.fs.Fs_T {
        .name = "rootfs",
        .flags = .R,
        .mount = rootfs_mount,
        .unmount = rootfs_umount,
    }),
};

pub fn init() ModErr_T!void {
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
