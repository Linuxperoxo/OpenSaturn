// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: tests.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const tests: type = @import("root").interfaces.tests;

/// --- SATURN RUNTIME TESTS ---
pub const __SaturnRTests__ = [_]tests.TestSuite {
    // Runtime Tests Location!
};

/// --- SATURN COMPTIME TESTS ---
pub const __SaturnCTests__ = [_]tests.TestSuite {
    // Comptime Tests Location!
};
