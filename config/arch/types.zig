// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Target_T: type = enum {
    i386,
    amd64,
    arm,
    avr,
    xtensa,
    riscv64,
};
pub const physIo_T: type = struct {
    maintainer: []const u8,
    entry: *const fn() void,
    sync: *const fn() void,
};
