// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: listeners.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const listeners: type = @import("listeners.zig");
const std: type = @import("std");
const types: type = @import("types.zig");
const test_types: type = @import("test_types.zig");

const PCIPhysIo_T: type = test_types.PCIPhysIo_T;
const PCIClass_T: type = test_types.PCIClass_T;
const PCIVendor_T: type = test_types.PCIVendor_T;

// === Teste Info ===
//
// OS: Gentoo Linux x86_64
// Zig: 0.15.2
// Tester: Linuxperoxo
// Status: MAYBE - FAILED WITH zig test -ODebug

const TestErr_T: type = error {
    UnreachableCode,
};

inline fn tree_clean() void {
    listeners.listeners_tree_root = .{
        .left = null,
        .phys = null,
        .right = null,
    };
}

test "Listeners Tree Adding" {
    var physio = [_]types.PhysIo_T {
        .{
            .brothers = 0,
            .events = .{},
            .flags = .{
                .find = 0,
                .hit = 0,
                .identified = 0,
                .link = 0,
                .save = 0,
            },
            .refs = 0,
            .status = .active,
            .private = @ptrFromInt(0x120893),
            .device = .{
                .bus = 0,
                .device = 0,
                .function = 0,
                .vendorID = @intCast(@intFromEnum(PCIVendor_T.amd)),
                .deviceID = 0xAB00,
                .class = @intCast(@intFromEnum(PCIClass_T.bridge)),
                .subclass = 0,
                .command = 0,
                .status = null,
                .prog = 0,
                .revision = null,
                .irq_line = 0,
                .irq_pin = 0,
                .bars = .{
                    null
                } ** 6,
            },
        }
    } ** 14;
    for(&physio, 0..) |*io, i| {
        io.device.bus = @intCast(i);
        try listeners.physio_listen(io);
        if(!listeners.physio_listener_search(io)) return TestErr_T.UnreachableCode;
    }
    tree_clean();
}

test "Listeners Tree Remove" {
    var physio = [_]types.PhysIo_T {
        .{
            .brothers = 0,
            .events = .{},
            .flags = .{
                .find = 0,
                .hit = 0,
                .identified = 0,
                .link = 0,
                .save = 0,
            },
            .refs = 0,
            .status = .active,
            .private = @ptrFromInt(0x120893),
            .device = .{
                .bus = 0,
                .device = 0,
                .function = 0,
                .vendorID = @intCast(@intFromEnum(PCIVendor_T.amd)),
                .deviceID = 0xAB00,
                .class = @intCast(@intFromEnum(PCIClass_T.bridge)),
                .subclass = 0,
                .command = 0,
                .status = null,
                .prog = 0,
                .revision = null,
                .irq_line = 0,
                .irq_pin = 0,
                .bars = .{
                    null
                } ** 6,
            },
        }
    } ** 14;
    for(&physio, 2..) |*io, i| {
        io.device.bus = @intCast(if(i % 2 == 0) i else i - 2);
        try listeners.physio_listen(io);
        if(!listeners.physio_listener_search(io)) return TestErr_T.UnreachableCode;
    }
    // verificando se a arvore nao quebrou
    try listeners.physio_listen_rm(&physio[7]);
    if(!listeners.physio_listener_search(&physio[13])) return TestErr_T.UnreachableCode;
    try listeners.physio_listen_rm(&physio[13]);
    if(!listeners.physio_listener_search(&physio[12])) return TestErr_T.UnreachableCode;
    tree_clean();
}
