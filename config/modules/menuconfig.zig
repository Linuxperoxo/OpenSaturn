// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: menuconfig.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Menuconfig: type = @import("types.zig").Menuconfig;
pub const Load: type = @import("types.zig").Load;

pub const modules_selection: Menuconfig = .{
    .ke_m_rootfs = .yes,
    .ke_m_devfs = .yes,
    .ke_m_fb = .yes,
};
