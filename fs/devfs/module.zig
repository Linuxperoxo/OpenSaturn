// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const target_T: type = @import("root").arch.target_T;

const Mod_T: type = @import("root").interfaces.module.Mod_T;
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;

const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const devfs_mount = &@import("management.zig").devfs_mount;
const devfs_umount = &@import("management.zig").devfs_umount;

pub const __linkable_module_name__: []const u8 = "ke_m_devfs";
pub const __linkable_module_init__: *const fn() anyerror!void = &init;
pub const __linkable_module_optional__: bool = false;
pub const __linkable_module_arch__: [4]target_T = .{
    .x86,
    .x86_64,
    .arm,
    .avr,
};

const devfsMod: *const Mod_T = &Mod_T {
    .name = "devfs",
    .desc = "Core Kernel Devices Filesystem",
    .author = "Linuxperoxo",
    .version = "1.0-1",
    .type = .filesystem,
    .init = &init,
    .exit = &exit,
    .private = &Fs_T {
        .name = "devfs",
        .flags = .RW,
        .mount = devfs_mount,
        .unmount = devfs_umount,
    },
};

fn init() ModErr_T!void {

}

fn exit() ModErr_T!void {

}
