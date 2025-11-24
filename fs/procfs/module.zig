// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("root").interfaces.module.Mod_T;
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;
const ModuleDescription_T: type = @import("root").interfaces.module.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = @import("root").interfaces.module.ModuleDescriptionTarget_T;

const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const procfs_mount = &@import("management.zig").procfs_mount;
const procfs_umount = &@import("management.zig").procfs_umount;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    .name = "ke_m_procfs",
    .load = .linkable,
    .init = &init,
    .deps = &[_][]const u8 {
        "ke_m_rootfs",
        "ke_m_sysfs",
    },
    .type = .{
        .filesystem = .{
            .compile = "/sys/proc"
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

const procfs: *const Mod_T = &Mod_T {
    .name = "ke_m_procfs",
    .desc = "Core Kernel Proc Filesystem",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .license = .{
        .know = .GPL2_only,
    },
    .type = .filesystem,
    .init = &init,
    .exit = &exit,
    .private = @constCast(&Fs_T {
        .name = "procfs",
        .flags = .R,
        //.mount = ,
        //.unmount = ,
    }),
};

fn init() ModErr_T!void {
    @call(.never_inline, &@import("root").interfaces.module.inmod, .{
        procfs
    }) catch |err| {
        return err;
    };
    // mkdir /sys/proc
}

fn exit() ModErr_T!void {
    @call(.never_inline, &@import("root").interfaces.module.rmmod, .{
        procfs
    }) catch |err| {
        return err;
    };
}
