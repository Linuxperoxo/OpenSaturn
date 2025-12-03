// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig     │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

pub const EventDefaultInstall_T: type = struct {
    bus: u2,
    line: u3,
    who: u8,
};
