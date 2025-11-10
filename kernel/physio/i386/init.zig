// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: init.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const scan: type = @import("scan.zig");

pub fn physio_init() callconv(.c) void {
    @call(.always_inline, scan.physio_scan, .{});
}
