// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: fb.zig      │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const devices: type = @import("root").interfaces.devices;
const module: type = @import("root").interfaces.module;
const device: type = @import("device.zig");
const ops: type = @import("ops.zig");

pub const __SaturnModuleDescription__: module.ModuleDescription_T = .{
    .mod = &vga_fb,
    .load = .linkable,
    .arch = &[_]module.ModuleDescriptionTarget_T {
        .i386,
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
    .init = 0,
    .exit = 0,
    .remove = 1,
    .anon = 1,
};

var major: devices.Major_T = 0;

fn init() anyerror!void {
    major = try devices.next_major();
    try devices.dev_add(major, &device.fb_device);
    errdefer devices.dev_rm(major, &device.fb_device) catch unreachable;
    try ops.set_video_physio();
}

fn exit() anyerror!void {
    errdefer {
        // klog()
    }
    try module.rmmod(&vga_fb);
    try devices.dev_rm(major, &device.fb_device);
    ops.unset_video_physio();
}
