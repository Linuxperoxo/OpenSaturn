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
    .arch = &[_]module.ModuleDescriptionTarget_T {
        .i386,
    },
    .deps = &[_][]const u8 {
        //"ke_m_devfs",
    },
    .type = .{
        .driver = {},
    },
    .flags = .{
        .call = .{
            .after = 0,
            .handler = 0,
        },
    },
};

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
    .after = &after,
    .private = .{
        .driver = &device.fb_device,
    },
    .flags = .{
        .control = .{
            .call = .{
                .after = 1,
                .init = 1,
                .exit = 1,
                .remove = 1,
                .handler = .{
                    .install = 1,
                    .remove = 1,
                },
            },
            .anon = 1,
        },
    },
};

fn init() anyerror!void {
    return module.inmod(&vga_fb);
}

fn after() anyerror!void {
    if(vga_fb.flags.internal.fault.call.init == 1)
        return exit();

    ops.video_physio() catch |err| {
        // klog();
        exit() catch return err;
        return err;
    };
}

fn exit() anyerror!void {
    module.rmmod(&vga_fb) catch {
        // klog();
    };
}
