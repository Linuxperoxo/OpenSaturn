// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: menuconfig.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Menuconfig_T: type = @import("types.zig").Menuconfig_T;
pub const Load_T: type = @import("types.zig").Load_T;

pub const FusiumSelection: Menuconfig_T = .{
    .some0 = .yes,
    .some1 = .yes,
};
