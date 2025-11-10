// ┌────────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test_waiting.zig   │
// │            Author: Linuxperoxo                     │
// └────────────────────────────────────────────────────┘

const waiting: type = @import("waiting.zig");
const std: type = @import("std");
const types: type = @import("types.zig");
const test_types: type = @import("test/types.zig");

const PCIPhysIo_T: type = test_types.PCIPhysIo_T;
const PCIClass_T: type = test_types.PCIClass_T;
const PCIVendor_T: type = test_types.PCIVendor_T;

// === Teste Info ===
//
// OS: Gentoo Linux x86_64
// Zig: 0.15.2
// Tester: Linuxperoxo
// Status: OK

const TestErr_T: type = error {
    UnreachableCode,
};

inline fn tree_clean() void {
    waiting.waiting_tree = .{
        .root = null,
    };
}

fn waiting0(_: *types.PhysIo_T) usize {
    return 0;
}

fn waiting1(_: *types.PhysIo_T) usize {
    return 1;
}

fn waiting2(_: *types.PhysIo_T) usize {
    return 2;
}

fn waiting3(_: *types.PhysIo_T) usize {
    return 3;
}

const fns = [_]*const fn(*types.PhysIo_T) usize {
    &waiting0,
    &waiting1,
    &waiting2,
    &waiting3,
};

test "Waiting Tree Adding" {
    var physio = types.PhysIo_T {
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
    };
    for(fns, 0..) |io, i| {
        try waiting.physio_wait_by(
            @intCast(i + 1),
            @intCast(i + 2),
            io
        );
        const found = try waiting.physio_wait_search(
            @intCast(i + 1),
            @intCast(i + 2)
        );
        if(found(&physio) != i) return TestErr_T.UnreachableCode;
    }
    tree_clean();
}
