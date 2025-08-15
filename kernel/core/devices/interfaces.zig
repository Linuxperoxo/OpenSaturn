// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const MinorNum_T: type = if(@sizeOf(usize) > 1) u16 else u8;

pub const Dev_T: type = struct {
    name: []const u8,
    write: *fn(u16, []const u8) anyerror!usize,
    read: *fn(u16, []u8) anyerror!usize,
    ioctrl: *fn(usize, usize) anyerror!usize,
};

pub const register_dev = @import("management.zig").register_dev;
pub const unregister_dev = @import("management.zig").unregister_dev;
