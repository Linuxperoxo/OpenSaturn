// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Load: type = enum {
    no,
    yes,
};

pub const Menuconfig: type = struct {
    ktask: Load,
};

