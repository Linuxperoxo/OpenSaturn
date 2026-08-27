// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: options.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");

const CodeMode: type = types.CodeMode;
const OptimizeMode: type = types.OptimizeMode;

pub const optimize_mode: OptimizeMode = .small;
pub const c_support: bool = true;
