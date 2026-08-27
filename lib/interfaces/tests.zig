// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: tests.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const TestSuite: type = struct {
    name: []const u8,
    tests: []struct {
        name: []const u8,
        func: *const fn() anyerror!void,
    },
    keep_going: u1 = 0,
};
