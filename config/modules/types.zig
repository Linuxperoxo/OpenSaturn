// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Load_T: type = enum {
    yes,
    no,
};

pub const Menuconfig_T: type = struct {
    ke_m_rootfs: Load_T,
    ke_m_devfs: Load_T,
    ke_m_somefs: Load_T,
};
