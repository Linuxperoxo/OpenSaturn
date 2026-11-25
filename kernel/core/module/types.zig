// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").interfaces.arch;

pub const ModType: type = enum(u8) {
    driver,
    syscall,
    irq,
    filesystem,
};

pub const ModLicense: type = enum(u8) {
    gpl2_only,
    gpl2_or_later,
    gpl3_only,
    gpl3_or_later,
    bsd_2_clause,
    bsd_3_clause,
    mit,
    apache_2_0,
    proprietary,
};

pub const Module: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    deps: ?[]const []const u8 = null,
    license: ModLicense,
    type: ModType,
    init: *const fn() anyerror!void,
    exit: *const fn() anyerror!void,
    targets: []arch.Target,
};
