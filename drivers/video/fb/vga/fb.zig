// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: fb.zig      │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const devices: type = @import("root").interfaces.devices;
const module: type = @import("root").interfaces.module;
const device: type = @import("device.zig");
const ops: type = @import("ops.zig");
const vfs: type = @import("root").interfaces.vfs;
const devfs: type = __SaturnModuleDescription__.request_lib("devfs-operations").?;

pub const __SaturnModuleDescription__: module.ModuleDescription_T = .{
    .mod = &vga_fb,
    .load = .linkable,
    .arch = &[_]module.ModuleDescriptionTarget_T {
        .i386,
    },
    .libs = .{
        .outside = &[_]module.ModuleDescriptionLibOut_T {
            module.ModuleDescriptionLibOut_T {
                .mod = "ke_m_devfs",
                .lib = "devfs-operations",
                .version = .{
                    .current = {},
                },
                .flags = .{
                    .required = 1,
                },
            },
        },
    },
};

const vga_fb: module.Mod_T = .{
    .name = "ke_m_fb",
    .desc = "Core Kernel VGA Framebuffer",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .license = .GPL2_only,
    .type = .driver,
    .deps = &[_][]const u8 {
        "ke_m_devfs"
    },
    .init = &init,
    .exit = &exit,
    .control = &vga_control,
};

var vga_control: module.ModControlFlags_T = .{
    .init = 1,
    .exit = 1,
    .remove = 1,
    .anon = 1,
};

var major: devices.Major_T = undefined;

fn init() anyerror!void {
    major =
    try devices.next_major();
    try devices.dev_add(major, &device.fb_device);

    errdefer devices.dev_rm(major, &device.fb_device) catch unreachable;
    try ops.set_video_physio();

    try devfs.create_device_node(major, 0, 0, 0, vfs.mode_T {
        .owner = vfs.R | vfs.W,
        .group = vfs.R | vfs.W,
        .other = 0,
    });
}

fn exit() anyerror!void {
    errdefer {
        // klog()
    }
    try module.rmmod(&vga_fb);
    try devices.dev_rm(major, &device.fb_device);
    ops.unset_video_physio();
}
