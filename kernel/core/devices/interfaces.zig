// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Dev_T: type = @import("types.zig").Dev_T;

pub const register_dev = @import("management.zig").register_dev;
pub const unregister_dev = @import("management.zig").unregister_dev;
