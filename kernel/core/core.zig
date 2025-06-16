// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const module: type = @import("module/module.zig");
pub const paging: type = @import("paging/paging.zig");
pub const vfs: type = @import("vfs/vfs.zig");
pub const devices: type =@import("devices/devices.zig");
pub const fs: type = @import("fs/fs.zig");
pub const panic: type = @import("panic.zig");

