// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: tests.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const tests: type = @import("root").interfaces.tests;

/// --- SATURN RUNTIME TESTS ---
pub const __SaturnRTests__ = [_]tests.TestSuite {
    // Tests Location!
};

/// --- SATURN COMPTIME TESTS ---
pub const __SaturnCTests__ = [_]tests.TestSuite {
    tests.TestSuite {
        .name = "test_fn",
        .@"fn" = &opaque {
            pub fn testFn() anyerror!void {
                return error.TestError;
            }
        }.testFn,
    }
    // Tests Location!
};
