// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: target.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const root: type = @import("../../build.zig");
const std: type = root.std;

pub const target: std.Target.Cpu.Arch = switch(root.SaturnArchConfig.Target) {
    .x86 => .x86,
    .x86_64 => .x86_64,
    .arm => .arm,
    .avr => .avr,
};

pub const optimize: std.builtin.OptimizeMode = switch(root.SaturnArchConfig.OptimizeMode) {
    .Small => .ReleaseSmall,
    .Fast => .ReleaseFast,
};


