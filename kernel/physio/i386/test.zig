// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
const types: type = @import("types.zig");
const tree: type = @import("tree.zig");

pub const PCIPhysIo_T: type = struct {
    bus: u8,
    device: u5,
    function: u3,
    vendorID: ?u16,
    deviceID: ?u16,
    class: ?u8,
    subclass: ?u8,
    command: ?u16,
    status: ?u16,
    prog: ?u8,
    revision: ?u8,
    irq_line: ?u8,
    irq_pin: ?u8,
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
};

test "PhysIo Tree Register Test" {
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = null,
        .deviceID = 0xAB00,
        .class = null,
        .subclass = 0,
        .command = null,
        .status = null,
        .prog = 0,
        .revision = null,
        .irq_line = null,
        .irq_pin = null,
        .bars = .{
            null
        } ** 6,
    };
    inline for(0..6) |i| {
        physio.class = @intCast(@typeInfo(PCIClass_T).@"enum".fields[i].value);
        inline for(0..11) |j| {
            physio.vendorID = @intCast(@typeInfo(PCIVendor_T).@"enum".fields[j].value);
            try tree.physio_register(physio);
            const physio_found = tree.physio_search(
                @as(types.PhysIoClass_T, @enumFromInt(@typeInfo(types.PhysIoClass_T).@"enum".fields[i].value)),
                @as(types.PhysIoVendor_T, @enumFromInt(@typeInfo(types.PhysIoVendor_T).@"enum".fields[j].value)),
            ) catch return TestErr_T.ExistsButNotFound;
            if(physio_found.device.class != physio.class or physio_found.device.vendorID != physio.vendorID)
                return TestErr_T.FoundSomeDiff;
        }
    }
}
