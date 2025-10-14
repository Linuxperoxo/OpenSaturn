// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: arch.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Target_T: type = @TypeOf(@import("root").config.arch.options.Target);
pub const ArchDescription_T: type = struct {
    text: []const u8,
    data: []const u8,
    usable: bool,
    entry: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.naked) noreturn,
    },
    init: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    },
    interrupts: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    },
    mm: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    },
};
