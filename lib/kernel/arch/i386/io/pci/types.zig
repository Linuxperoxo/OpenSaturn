// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const PCIAddress: type = packed struct {
    register: PCIRegsOffset,
    function: u3,
    device: u5,
    bus: u8,
    reserved: u7 = 0,
    enable: u1,
};

pub const PCIPhysIo: type = struct {
    bus: u8,
    device: u5,
    function: u3,
    vendor_id: u16,
    device_id: u16,
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
            mmio,
            port
        },
    },
};

pub const PCIClass: type = enum(u8) {
    storage = 0x01,
    network = 0x02,
    display = 0x03,
    multimedia = 0x04,
    bridge = 0x06,
    sbus = 0x0C,
    _,
};

pub const PCIVendor: type = enum(u16) {
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

pub const PCIRegsOffset: type = enum(u8) {
    vendor_id = 0x00,
    device_id = 0x02,
    command = 0x04,
    status = 0x06,
    revision = 0x08,
    prog = 0x09,
    subclass = 0x0A,
    class = 0x0B,
    cache_line_size = 0x0C,
    latency_timer = 0x0D,
    header_type = 0x0E,
    bist = 0x0F,
    bar0 = 0x10,
    bar1 = 0x14,
    bar2 = 0x18,
    bar3 = 0x1C,
    bar4 = 0x20,
    bar5 = 0x24,
    cardbus_cis_pointer = 0x28,
    subsystem_vendor_id = 0x2C,
    subsystem_id = 0x2E,
    expansion_rom_base = 0x30,
    capabilities_pointer = 0x34,
    irq_line = 0x3C,
    irq_pin = 0x3D,
    min_grant = 0x3E,
    max_latency = 0x3F,
};
