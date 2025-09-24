// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: memory.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const SOA: type = switch(@import("builtin").is_test) {
    true => @import("test/SOA/SOA.zig"),
    false => @import("root").memory.SOA,
};
