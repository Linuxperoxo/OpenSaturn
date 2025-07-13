// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// kernel modules types
const Mod_T: type = @import("root").interfaces.module.Mod_T;
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;

// kernel fs types
const Fs_T: type = @import("root").interfaces.fs.Fs_T;

// NOTE:
// Para ser um modulo visivel para selecionar como y ou n ele deve ter 
// um __linkable_module_name__ do tipo []const u8 falando o nome do modulo
// que deve ser o mesmo nome em __linkable__.name
pub const __linkable_module_name__: []const u8 = "ke_m_rootfs";
pub const __linkable__: @import("root").interfaces.module.LinkModInKernel = .{
    .name = "ke_m_rootfs",
    .init = &init,
};

const rootfsMod: Mod_T = .{
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
        .mount = @constCast(&@import("management.zig").rootfs_mount),
        .unmount = @constCast(&@import("management.zig").rootfs_unmount),
    }),
};

pub fn init() ModErr_T!void {
    @call(.never_inline, @import("root").interfaces.module.inmod, .{
        rootfsMod
    }) catch |err| {
        return err;
    };
}

fn exit() ModErr_T!void {
    @call(.never_inline, &(@import("root").interfaces.module.rmmod), .{
        rootfsMod.name
    }) catch |err| {
        return err;
    };
}
