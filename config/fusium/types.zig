// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Load_T: type = enum {
    no,
    yes,
};

pub const Menuconfig_T: type = struct {
    ktask: Load_T,
};

