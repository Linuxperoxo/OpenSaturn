// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const CodeMode: type = enum {
    debug,
    runtime,
};
pub const OptimizeMode: type = enum {
    small,
    fast,
};
