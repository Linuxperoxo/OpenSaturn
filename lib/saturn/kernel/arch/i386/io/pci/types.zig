// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const PCIAddress_T: type = packed struct {
    register: PCIRegsOffset_T,
    function: u3,
    device: u5,
    bus: u8,
    reserved: u7 = 0,
    enable: u1,
};

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

pub const PCIRegsOffset_T: type = enum(u8) {
    vendorID = 0x00,
    deviceID = 0x02,
    command = 0x04,
    status = 0x06,
    revision = 0x08,
    prog = 0x09,
    subclass = 0x0A,
    class = 0x0B,
    cacheLineSize = 0x0C,
    latencyTimer = 0x0D,
    headerType = 0x0E,
    bist = 0x0F,
    bar0 = 0x10,
    bar1 = 0x14,
    bar2 = 0x18,
    bar3 = 0x1C,
    bar4 = 0x20,
    bar5 = 0x24,
    cardbusCISPointer = 0x28,
    subsystemVendorID = 0x2C,
    subsystemID = 0x2E,
    expansionROMBase = 0x30,
    capabilitiesPointer = 0x34,
    irq_line = 0x3C,
    irq_pin = 0x3D,
    minGrant = 0x3E,
    maxLatency = 0x3F,
};
