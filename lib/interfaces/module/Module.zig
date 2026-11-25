// ┌───────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: Module.zig    │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const arch: type = @import("root").interfaces.arch;

pub const Type: type = enum(u8) {
    driver,
    syscall,
    irq,
    filesystem,
};

pub const License: type = enum(u8) {
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

name: []const u8,
desc: []const u8,
version: []const u8,
author: []const u8,
deps: ?[]const []const u8 = null,
license: License,
type: Type,
init: *const fn() anyerror!void,
exit: *const fn() anyerror!void,
targets: []arch.Target,
