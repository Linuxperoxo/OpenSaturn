// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: menuconfig.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Menuconfig: type = @import("types.zig").Menuconfig;
pub const Load: type = @import("types.zig").Load;

pub const fusium_selection: Menuconfig = .{
    .ktask = .yes,
};
