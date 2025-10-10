// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Target_T: type = enum {
    x86,
    x86_64,
    arm,
    avr,
    xtensa,
    riscv,
};
