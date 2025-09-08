// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const target_T: type = enum {
    x86,
    x86_64,
    arm,
    avr,
    xtensa
};
pub const codeMode_T: type = enum {
    Debug,
    Runtime,
};
pub const optimize_T: type = enum {
    Small,
    Fast
};
pub const arch_T: type = struct {
    maintainer: []const u8,
    usable: bool,
    init: *const fn() void,
    interrupt: enum { // NOTE: Possibly obsolete
        raw,
        supervisor,
    },
};
pub const entry_T: type = struct {
    maintainer: []const u8,
    entry: *const fn() callconv(.naked) noreturn,
    label: []const u8,
    section: []const u8,
};
