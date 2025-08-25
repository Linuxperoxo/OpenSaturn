// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: target.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const root: type = @import("../../build.zig");
const std: type = root.std;

pub const target: std.Target.Cpu.Arch = switch(root.SaturnArchConfig.options.Target) {
    .x86 => .x86,
    .x86_64 => .x86_64,
    .arm => .arm,
    .avr => .avr,
    .xtensa => .xtensa,
};

pub const optimize: std.builtin.OptimizeMode = switch(root.SaturnArchConfig.options.OptimizeMode) {
    .Small => .ReleaseSmall,
    .Fast => .ReleaseFast,
};


