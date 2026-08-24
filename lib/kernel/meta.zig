// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: meta.zig       │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const fmt: type = @import("meta/comptime_fmt.zig");
pub const slice: type = @import("meta/slice.zig");

// Compatibility alias while callers migrate to meta.slice.
pub const utils: type = slice;
