// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devices.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Device: type = struct {
    name: []const u8,
    type: enum {char, block},
    write: *fn([]const u8) u32,
    read: *fn(u32, u32) []const u8,
    ioctrl: *fn(u32, []const u8) anyerror!u32,
};

pub fn register_dev(dev: Device) enum {ok, err} {
    return .ok;
}

pub fn unregister_dev(name: []const u8) void {

}

