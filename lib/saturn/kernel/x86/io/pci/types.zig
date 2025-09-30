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
