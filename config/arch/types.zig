// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const target_T: type = enum { x86, x86_64, arm, avr };
pub const codeMode_T: type = enum { Debug, Runtime };
pub const optimize_T: type = enum { Small, Fast };
pub const arch_T: type = struct {
    maintainer: []const u8,
    usable: bool,
    init: *fn() void,
    entry: *fn() callconv(.naked) noreturn,
    interrupt: enum {
        raw,
        supervisor,
    },
};
