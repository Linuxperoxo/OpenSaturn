// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: video.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const VGA: type = @import("vga.zig");
const VESA: type = @import("vesa.zig");

pub const VGAForegroundColor: type = VGA.CharColor;
pub const VGABackgroundColor: type = VGA.BackColor;

const VideoDriver: type = union(enum(u1)) {
    vga: @import("root").drivers.DriverInterface,
    vesa: @import("root").drivers.DriverInterface,
};

pub const VideoCommand: type = enum(u4) {
    @"write",
    @"down",
    @"setPtr",
    @"clear",
    @"setColor",
};

pub const VideoQuery: type = enum(u4) {
    @"currentX",
    @"currentY",
    @"currentCColor",
    @"currentBColor",
};

pub const activeDriver: VideoDriver = VideoDriver {
    .vga = VGA.loadDriver(),
};
