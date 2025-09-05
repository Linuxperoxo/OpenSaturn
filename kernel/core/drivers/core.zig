// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Driver_T: type = @import("types.zig").Driver_T;
const DriverErr_T: type = @import("types.zig").DriverErr_T;
const Ops_T: type = @import("types.zig").Ops_T;
const OpsErr_T: type = @import("types.zig").OpsErr_T;

const Allocator: type = @import("allocator.zig");

pub fn register(comptime D: *const Driver_T) void {
    _ = D;
}

pub fn unregister(N: []const u8) void {
    _ = N;
}

