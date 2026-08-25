// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: init.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const scan: type = @import("scan.zig");

pub noinline fn physioInit() callconv(.c) void {
    @call(.always_inline, scan.physioScan, .{});
}
