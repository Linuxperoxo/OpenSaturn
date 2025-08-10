// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: target.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const root: type = @import("../../build.zig");
const std: type = root.std;

const __SaturnTarget__ = root.SaturnArchInfo.__SaturnTarget__;
const __SaturnOptimize__ = root.SaturnArchInfo.__SaturnOptimize__;

pub const target: std.Target.Cpu.Arch = switch(__SaturnTarget__) {
    .x86 => .x86,
    .x86_64 => .x86_64,
    .arm => .arm,
    .avr => .avr,
};

pub const optimize: std.builtin.OptimizeMode = switch(__SaturnOptimize__) {
    .Small => .ReleaseSmall,
    .Fast => .ReleaseFast,
};


