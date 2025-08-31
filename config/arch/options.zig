// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: options.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const target_T: type = @import("types.zig").target_T;
const codeMode_T: type = @import("types.zig").codeMode_T;
const optimize_T: type = @import("types.zig").optimize_T;

pub const Target: target_T = .x86;
pub const CodeMode: codeMode_T = .Runtime;
pub const OptimizeMode: optimize_T = .Small;
