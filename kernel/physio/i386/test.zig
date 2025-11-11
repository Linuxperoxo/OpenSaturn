// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
const types: type = @import("types.zig");
const tree: type = @import("tree.zig");

// === Teste Info ===
//
// OS: Gentoo Linux x86_64
// Zig: 0.15.2
// Tester: Linuxperoxo
// Status: MAYBE

pub const PCIPhysIo_T: type = struct {
    bus: u8,
    device: u5,
    function: u3,
    vendorID: u16,
    deviceID: u16,
    class: u8,
    subclass: u8,
    command: u16,
    status: ?u16,
    prog: ?u8,
    revision: ?u8,
    irq_line: u8,
    irq_pin: u8,
    bars: [6]?struct {
        addrs: u32,
        type: enum(u1) {
            MMIO,
            PORT
        },
    },
};

pub const PCIClass_T: type = enum(u8) {
    storage = 0x01,
    network = 0x02,
    display = 0x03,
    multimedia = 0x04,
    bridge = 0x06,
    sbus = 0x0C,
    _,
};

pub const PCIVendor_T: type = enum(u16) {
    intel = 0x8086,
    amd = 0x1002,
    nvidia = 0x10DE,
    broadcom = 0x14E4,
    realtek = 0x10EC,
    qualcomm = 0x168C,
    marvell = 0x11AB,
    vmware = 0x15AD,
    virtio = 0x1AF4,
    virtualbox = 0x80EE,
    qemu = 0x1234,
    _,
};

const TestErr_T: type = error {
    FoundSomeDiff,
    ExistsButNotFound,
    BrotherHasBrother,
    BrotherNotLinked,
    BrothersDiffQuant,
};

test "PhysIo Tree Register Test" {
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0,
        .deviceID = 0xAB00,
        .class = 0,
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
    };
    inline for(0..6) |c| {
        physio.class = @intCast(@typeInfo(PCIClass_T).@"enum".fields[c].value);
        inline for(0..11) |v| {
            physio.vendorID = @intCast(@typeInfo(PCIVendor_T).@"enum".fields[v].value);
            try tree.physio_register(physio);
            const physio_found = tree.physio_search(
                .{
                    .identified = .{
                        .class = @as(types.PhysIoClass_T, @enumFromInt(@typeInfo(types.PhysIoClass_T).@"enum".fields[c].value)),
                        .vendor = @as(types.PhysIoVendor_T, @enumFromInt(@typeInfo(types.PhysIoVendor_T).@"enum".fields[v].value)),
                    }
                }
            ) catch return TestErr_T.ExistsButNotFound;
            if(physio_found.device.class != physio.class or physio_found.device.vendorID != physio.vendorID)
                return TestErr_T.FoundSomeDiff;
        }
    }
}

test "PhysIo Tree Brothers Test" {
    const total_of_brothers: comptime_int = 14;
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0x1283,
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
    };
    try tree.physio_register(physio);
    physio.bus += 1;
    for(0..total_of_brothers) |_| {
        try tree.physio_register(physio);
        physio.bus += 1;
    }
    const physio_found = tree.physio_search(
        .{
            .unidentified = .{
                .class = .bridge,
                .vendor = 0x1283,
                .deviceID = 0xAB00,
            }
        }
    ) catch return TestErr_T.ExistsButNotFound;
    //if(physio_found.brothers != total_of_brothers) return TestErr_T.BrothersDiffQuant;
    var brothers: [total_of_brothers - 1]*types.PhysIo_T = undefined;
    try tree.physio_brother(physio_found, brothers[0..13]);
    for(brothers) |brother| {
        if(brother.brothers != 0) return TestErr_T.BrotherHasBrother;
        const phys_info: *types.PhysIoInfo_T = @alignCast(@ptrCast(brother.private));
        if(phys_info.brother != null) return TestErr_T.BrotherHasBrother;
        if(@intFromPtr(phys_info.older_brother) != @intFromPtr(physio_found.private)) return TestErr_T.BrotherNotLinked;
    }
}

test "PhysIo Tree Register Unidentified Test" {
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0,
        .deviceID = 0xAB00,
        .class = 0,
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
    };
    inline for(0..6) |c| {
        physio.class = @intCast(@typeInfo(PCIClass_T).@"enum".fields[c].value);
        inline for(0..11) |v| {
            physio.vendorID = @intCast(v);
            try tree.physio_register(physio);
            const physio_found = tree.physio_search(
                .{
                    .unidentified = .{
                        .class = @as(types.PhysIoClass_T, @enumFromInt(@typeInfo(types.PhysIoClass_T).@"enum".fields[c].value)),
                        .vendor = physio.vendorID,
                        .deviceID = physio.deviceID,
                    }
                }
            ) catch return TestErr_T.ExistsButNotFound;
            if(physio_found.device.class != physio.class or physio_found.device.vendorID != physio.vendorID)
                return TestErr_T.FoundSomeDiff;
        }
    }
}

test "PhysIo Tree Register Unidentified DeviceID Collision Test" {
    const base_vendorID: comptime_int = 0xAB00;
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0,
        .deviceID = 0xAB00,
        .class = @intFromEnum(PCIClass_T.storage),
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
    };
    for(0..32) |d| {
        physio.vendorID = @intCast(base_vendorID + d);
        try tree.physio_register(physio);
    }
    for(0..32) |d| {
        const physio_found: *types.PhysIo_T = tree.physio_search(.{
            .unidentified = .{
                .class = .storage,
                .deviceID = 0xAB00,
                .vendor = @intCast(base_vendorID + d),
            }
        }) catch return TestErr_T.ExistsButNotFound;
        if(physio_found.device.vendorID != base_vendorID + d)
            return TestErr_T.FoundSomeDiff;
    }
}

test "PhysIo Tree Register Unidentified VendorID Collision Test" {
    const base_deviceID: comptime_int = 0xAB00;
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0x7162,
        .deviceID = 0,
        .class =  @intFromEnum(PCIClass_T.storage),
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
    };
    for(0..32) |d| {
        physio.deviceID = @intCast(base_deviceID + d);
        try tree.physio_register(physio);
    }
    for(0..32) |d| {
        const physio_found: *types.PhysIo_T = tree.physio_search(
            .{
                .unidentified = .{
                    .class = .storage,
                    .deviceID = @intCast(base_deviceID + d),
                    .vendor = 0x7162,
                }
            }
        ) catch return TestErr_T.ExistsButNotFound;
        if(physio_found.device.deviceID != base_deviceID + d)
            return TestErr_T.FoundSomeDiff;
    }
}
