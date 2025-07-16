// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// kernel modules types
const Mod_T: type = @import("root").interfaces.module.Mod_T;
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;

// kernel fs types
const Fs_T: type = @import("root").interfaces.fs.Fs_T;

pub const __linkable_module_name__: []const u8 = "ke_m_rootfs";
pub const __linkable_module_init__: *const fn() anyerror!void = &init;

const devfsMod: Mod_T = .{
    .name = "devfs",
    .desc = "Core Kernel Device Filesystem",
    .author = "Linuxperoxo",
    .version = "1.0-1",
    .type = .filesystem,
    .init = &initfs,
    .exit = &exitfs,
    .private = @constCast(&@import("root").interfaces.fs.Fs_T {
        .name = "devfs",
        .flags = .R,
        .mount = @constCast(&@import("management.zig").rootfs_mount),
        .unmount = @constCast(&@import("management.zig").rootfs_unmount),
    }),
};

const devfsSyscallsMod: Mod_T = .{
    .name = "devfs syscalls",
    .desc = "Core Kernel Syscalls for Device Filesystem",
    .author = "Linuxperoxo",
    .version = "1.0-1",
    .type = .syscall,
    .init = &initsyscall,
    .exit = &exitsyscall,
    .private = null,
};

fn init() ModErr_T!void {
    @call(.always_inline, &initfs, .{}) catch |err| return err;
    @call(.always_inline, &initsyscall, .{}) catch |err| return err;
}

fn initfs() ModErr_T!void {
    @call(.never_inline, @import("root").interfaces.module.inmod, .{
        devfsMod
    }) catch |err| {
        return err;
    };
}

fn exitfs() ModErr_T!void {
    @call(.never_inline, &(@import("root").interfaces.module.rmmod), .{
        devfsMod.name
    }) catch |err| {
        return err;
    };
}

fn initsyscall() ModErr_T!void {

}

fn exitsyscall() ModErr_T!void {

}
