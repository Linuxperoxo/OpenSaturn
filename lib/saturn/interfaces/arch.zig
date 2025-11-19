// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: arch.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Target_T: type = @TypeOf(@import("root").config.arch.options.Target);
pub const ArchDescription_T: type = struct {
    usable: bool,
    entry: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.naked) noreturn,
    },
    init: ?struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    },
    interrupts: ?struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    },
    mm: ?struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    },
    physio: ?struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
        sync: *const fn() void,
    },
    extra: ?[]const Extra_T,
    data: ?[]const Data_T,

    pub const Extra_T: type = struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    };

    pub const Data_T: type = struct {
        label: []const u8,
        section: ?[]const u8,
        ptr: *const anyopaque,
    };
};
