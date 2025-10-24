// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: options.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");

const CodeMode_T: type = types.CodeMode_T;
const OptimizeMode_T: type = types.OptimizeMode_T;

pub const CodeMode: CodeMode_T = .Debug;
pub const OptimizeMode: OptimizeMode_T = .Small;
