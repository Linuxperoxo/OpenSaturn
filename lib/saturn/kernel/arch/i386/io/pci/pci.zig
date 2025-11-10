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

pub const PCIAddress_T: type = @import("types.zig").PCIAddress_T;
pub const PCIRegsOffset_T: type = @import("types.zig").PCIRegsOffset_T;
pub const PCIPhysIo_T: type = @import("types.zig").PCIPhysIo_T;
pub const PCIClass_T: type = @import("types.zig").PCIClass_T;
pub const PCIVendor_T: type = @import("types.zig").PCIVendor_T;

pub const PCI_UNDEFINED_RETURN: u32 = 0xFFFFFFFF; // or ~0x0;

const PCI_CONFIG_ADDRESS_PORT: u16 = 0xCF8;
const PCI_CONFIG_DATA_PORT: u16 = 0xCFC;

pub fn pci_config_write(address: PCIAddress_T, data: u32) void {
    @call(.always_inline, &out.l, .{
        PCI_CONFIG_ADDRESS_PORT,
        @as(u32, @bitCast(address)),
    });
    @call(.always_inline, &out.l, .{
        PCI_CONFIG_DATA_PORT,
        data,
    });
}

pub fn pci_config_read(address: PCIAddress_T) u32 {
    @call(.always_inline, &out.l, .{
        PCI_CONFIG_ADDRESS_PORT,
        @as(u32, @bitCast(address))
    });
    return @call(.always_inline, &in.l, .{
        PCI_CONFIG_DATA_PORT,
    });
}
