// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: fb.zig      │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const devices: type = @import("root").interfaces.devices;
const module: type = @import("root").interfaces.module;
const device: type = @import("device.zig");
const ops: type = @import("ops.zig");

pub const __SaturnModuleDescription__: module.ModuleDescription_T = .{
    .name = "ke_m_vga_fb",
    .load = .linkable,
    .init = &init,
    .type = .driver,
    .arch = &[_]module.ModuleDescriptionTarget_T {
        .i386,
    },
    .deps = &[_][]const u8 {
        //"ke_m_devfs",
    },
};

var major: devices.Major_T = 0;
var vga_fb: module.Mod_T = .{
    .name = __SaturnModuleDescription__.name,
    .desc = "Core Kernel VGA Framebuffer",
    .author = "Linuxperoxo",
    .version = "0.1.0",
    .deps = __SaturnModuleDescription__.deps,
    .license = .GPL2_only,
    .type = .driver,
    .init = &init,
    .exit = &exit,
    .private = .{
        .driver = &device.fb_device,
    },
    .flags = .{
        .control = .{
            .call = .{
                .after = 1,
                .init = 0,
                .exit = 0,
                .remove = 1,
            },
            .anon = 1,
        },
    },
};

fn init() anyerror!void {
    try module.inmod(&vga_fb);
    errdefer module.rmmod(&vga_fb) catch {};
    major = try devices.next_major();
    try devices.dev_add(major, vga_fb.private.driver);
    errdefer devices.dev_rm(major, vga_fb.private.driver) catch unreachable;
    try ops.set_video_physio();
}

fn exit() anyerror!void {
    errdefer {
        // klog()
    }
    try module.rmmod(&vga_fb);
    try devices.dev_rm(major, vga_fb.private.driver);
    ops.unset_video_physio();
}
