// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: srtr.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const rtests: type = @import("root").rtests;
const tests: type = @import("root").interfaces.tests;

// Saturn Runtime Tests Runner

pub fn saturnTestRunner() void {
    var ok: usize = 0;
    var fail: usize = 0;

    for(rtests.__SaturnRTests__) |test_suite | {
        for(test_suite.tests) |@"test"| {
            @call(.never_inline, @"test".func, .{}) catch |err| {
                const err_name: []const u8 = @errorName(err);
                _ = err_name;

                //klog("[KERNEL TESTS]: FAILED ({s}): {s}", .{ @"test".name, err_name });

                fail += 1;
                continue;
            };
            ok += 1;
        }
        //klog("[KERNEL TESTS]: Result \"{s}\" [ OK = {d} | FAIL = {d} ]", .{ test_suite.name, ok, fail});
    }
}
