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

// TODO: Talvez dividir em 2 enum, um para comando de read
//       e outro para write

pub const VideoCommand: type = enum(u4) {
    @"write",
    @"down",
    @"clear",
    @"attribute",
};

pub const activeDriver: VideoDriver = VideoDriver {
    .vga = VGA.loadDriver(),
};
