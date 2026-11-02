// ┌───────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: comptime.zig  │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const config: type = @import("root").config.kernel;
const tests: type = @import("root").tests;

pub fn execComptimeTests() void {
    if(!config.test_suite.comptimeTestEnable)
        return;

    for(tests.__SaturnCTests__) |t| {
        t.@"fn"() catch |err| {
            @compileError(
                "TEST_FAIL: " ++ "\"" ++ t.name ++ "\" -> " ++ @errorName(err)
            );
        };
    }
}
