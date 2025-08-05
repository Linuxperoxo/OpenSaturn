// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: pci.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘


const out: type = struct {
    pub const b = @import("root").kernel.io.ports.outb;
    pub const w = @import("root").kernel.io.ports.outw;
    pub const l = @import("root").kernel.io.ports.outl;
};

const in: type = struct {
    pub const b = @import("root").kernel.io.ports.inb;
    pub const w = @import("root").kernel.io.ports.inw;
    pub const l = @import("root").kernel.io.ports.inl;
};

const PCI_CONFIG_ADDRESS: u16 = 0xCF8;
const PCI_CONFIG_DATA: u16 = 0xCFC;

pub const PciAddress: type = packed struct {
    AlignRegisterOffset: u2 = 0,
    RegisterOffset: u6,
    FunctionNumber: u3,
    DeviceNumber: u5,
    BusNumber: u8,
    Reserved: u7 = 0,
    Enable: u1,
};

const PciDevice: type = packed struct {
    BusNumber: u8,
    Device: u8,
    VendorID: u16,
    DeviceID: u16,
    ClassCode: u8,
    SubClass: u8,
    ProgIF: u8,
};

pub fn pci_config_write(Address: PciAddress, Data: u32) void {
    Address.RegisterOffset &= 0xFC; // Precisa ser alinhado
    @call(
        .always_inline,
        &out.l,
        .{
            PCI_CONFIG_ADDRESS,
            @as(u32, @bitCast(Address)),
        }
    );
    @call(
        .always_inline,
        &out.l,
        .{
            PCI_CONFIG_DATA,
            Data,
        }
    );
}

pub fn pci_config_read(Address: PciAddress) u32 {
    @call(
        .always_inline,
        &out.l,
        .{
            PCI_CONFIG_ADDRESS,
            @as(u32, @bitCast(Address))
        }
    );
    return @call(
        .always_inline,
        &in.l,
        .{
            PCI_CONFIG_DATA,
        }
    );
}

// TODO: pub fn pci_scan_bus() 
// TODO: pub fn pci_get_device(VendorID: u16, DeviceID: u16)
// TODO: pub fn pci_enable_bus_mastering()
