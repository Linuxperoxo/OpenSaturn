// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: arch.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const target_T: type = @import("root").config.arch.types.target_T;
pub const codeMode_T: type = @import("root").config.arch.types.codeMode_T;
pub const optimize_T: type = @import("root").config.arch.types.optimize_T;
pub const ArchDescription_T: type = struct {
    section: []const u8,
    entry: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.naked) noreturn,
    },
    init: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() void,
    },
    interrupts: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() void,
    },
    mm: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() void,
    },
    usable: bool,
};
