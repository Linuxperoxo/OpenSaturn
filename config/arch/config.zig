// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: config.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const target_T: type = @import("types.zig").target_T;
const codeMode_T: type = @import("types.zig").codeMode_T;
const optimize_T: type = @import("types.zig").optimize_T;

const arch: type = @import("root").arch;

pub const Target: target_T = .x86;
pub const CodeMode: codeMode_T = .Debug;
pub const OptimizeMode: optimize_T = .Small;

