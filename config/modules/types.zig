// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Load: type = enum {
    no,
    yes,
};

pub const Menuconfig: type = struct {
    ke_m_rootfs: Load,
    ke_m_devfs: Load,
    ke_m_fb: Load,
};
