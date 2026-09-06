// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: fb.zig      │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const devices: type = @import("root").interfaces.devices;
const module: type = @import("root").interfaces.module;
const device: type = @import("device.zig");
const ops: type = @import("ops.zig");
const vfs: type = @import("root").interfaces.vfs;
const devfs: type = __SaturnModuleDescription__.requestLib("devfs-operations").?;

pub const __SaturnModuleDescription__: module.ModuleDescription = .{
    .mod = &vga_fb,
    .load = .linkable,
    .insf = .{
        .anon = 0,
        .init = 1,
        .exit = 1,
        .remove = 0,
    },
    .arch = &[_]module.ModuleDescriptionTarget {
        .i386,
    },
    .libs = .{
        .outside = &[_]module.ModuleDescriptionLibOut {
            module.ModuleDescriptionLibOut {
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

const vga_fb: module.Mod = .{
    .name = "ke_m_fb",
    .desc = "Core Kernel VGA Framebuffer",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .deps = &[_][]const u8 {
        "ke_m_devfs"
    },
    .license = .gpl2_only,
    .type = .driver,
    .init = &init,
    .exit = &exit,
};

var major: devices.Major = undefined;

fn init() anyerror!void {
    major = try devices.nextMajorForDevice();
    try devices.addDevice(major, &device.fb_device);

    errdefer devices.rmDevice(major, &device.fb_device) catch unreachable;
    try ops.setVideoPhysio();

    try devfs.createDeviceNode(major, 0, 0, 0, vfs.Mode {
        .owner = vfs.r | vfs.w,
        .group = vfs.r | vfs.w,
        .other = 0,
    });
}

fn exit() anyerror!void {
    errdefer {
        // klog()
    }
    try devices.rmDevice(major, &device.fb_device);
    ops.unsetVideoPhysio();
    try vga_fb.rmmod();
}
