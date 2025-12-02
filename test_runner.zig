// ┌──────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test_runner.zig  │
// │            Author: Linuxperoxo                   │
// └──────────────────────────────────────────────────┘

//! OpenSaturn Test Runner

const std: type = @import("std");
const builtin: type = @import("builtin");
const saturn: type = @import("saturn");

pub const cpu: type = saturn.cpu;
pub const arch: type = saturn.cpu.arch;
pub const core: type = saturn.core;
pub const interfaces: type = saturn.interfaces;
pub const supervisor: type = saturn.supervisor;
pub const lib: type = saturn.lib;
pub const kernel: type = saturn.lib.kernel;
pub const userspace: type = saturn.lib.userspace;
pub const config: type = saturn.config;

pub fn main() void {
    var ok: usize = 0;
    var skip: usize = 0;
    var failed: usize = 0;
    const test_functions = builtin.test_functions;
    for(test_functions, 0..) |test_fn, i| {
        std.debug.print("({d}/{d}) {s}...", .{ i + 1, test_functions.len, test_fn.name });
        if(test_fn.func()) {
            ok += 1;
            std.debug.print("OK\n", .{});
        } else |err| switch(err) {
            error.SaturnTestSkip => {
                skip += 1;
                std.debug.print("SKIP\n", .{});
            },
            else => {
                failed += 1;
                std.debug.print("FAIL ({s})\n", .{
                    @errorName(err),
                });
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpStackTrace(trace.*);
                }
            },
        }
    }
}
