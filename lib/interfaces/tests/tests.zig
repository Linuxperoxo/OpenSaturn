// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: tests.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const TestSuite: type = struct {
    name: []const u8,
    @"fn": *const fn() anyerror!void,
    keep_going: u1 = 0, // only valid for runtime tests
};
