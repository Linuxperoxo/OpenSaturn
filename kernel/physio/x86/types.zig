// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const PhysIo_T: type = struct {
    device: PCI_T,

    pub const PCI_T: type = struct {
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
            type: enum(u1) { MMIO, PORT },
        },
    };
};

pub const PCIClassesIDs_T: type = enum(u8) {
    storage = 0x01,
    network = 0x02,
    display = 0x03,
    multimedia = 0x04,
    bridge = 0x06,
    sbus = 0x0C,
    _,
};

pub const PCIVendorIDs_T: type = enum(u16) {
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

pub const PCIClass_T: type = enum {
    storage,
    network,
    display,
    multimedia,
    sbus,
};

pub const PCIVendor_T: type = enum {
    intel,
    amd,
    nvidia,
    broadcom,
    realtek,
    qualcomm,
    marvell,
    vmware,
    virtio,
    virtualbox,
    qemu,
    unknown,
};


pub const PhysIoType_T: type = struct {
    class: PCIClass_T,
    vendor: PCIVendor_T,
    device: ?u16,
};

pub const PhysIoInfo_T: type = struct {
    mok: u25,
    phys: PhysIo_T,
    status: Status_T,

    pub const Status_T: type = enum {
        missing,
        active,
        working
    };
};

pub const PhysIOErr_T: type = error {
    NoMok,
    Blocked,
    Missing
};

