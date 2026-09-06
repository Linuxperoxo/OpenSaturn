// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: pci.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const out: type = struct {
    pub const b = @import("root").__SaturnArchImpl__.lib.kernel.io.ports.outb;
    pub const w = @import("root").__SaturnArchImpl__.lib.kernel.io.ports.outw;
    pub const l = @import("root").__SaturnArchImpl__.lib.kernel.io.ports.outl;
};

const in: type = struct {
    pub const b = @import("root").__SaturnArchImpl__.lib.kernel.io.ports.inb;
    pub const w = @import("root").__SaturnArchImpl__.lib.kernel.io.ports.inw;
    pub const l = @import("root").__SaturnArchImpl__.lib.kernel.io.ports.inl;
};

pub const PCIAddress: type = @import("types.zig").PCIAddress;
pub const PCIRegsOffset: type = @import("types.zig").PCIRegsOffset;
pub const PCIPhysIo: type = @import("types.zig").PCIPhysIo;
pub const PCIClass: type = @import("types.zig").PCIClass;
pub const PCIVendor: type = @import("types.zig").PCIVendor;

pub const pci_undefined_return: u32 = 0xFFFFFFFF; // or ~0x0;

const pci_config_address_port: u16 = 0xCF8;
const pci_config_data_port: u16 = 0xCFC;

pub fn pciConfigWrite(address: PCIAddress, data: u32) void {
    @call(.always_inline, &out.l, .{
        pci_config_address_port,
        @as(u32, @bitCast(address)),
    });
    @call(.always_inline, &out.l, .{
        pci_config_data_port,
        data,
    });
}

pub fn pciConfigRead(address: PCIAddress) u32 {
    @call(.always_inline, &out.l, .{
        pci_config_address_port,
        @as(u32, @bitCast(address))
    });
    return @call(.always_inline, &in.l, .{
        pci_config_data_port,
    });
}
