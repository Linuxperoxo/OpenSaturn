// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const pci: type = @import("root").__SaturnArchImpl__.lib.kernel.io.pci;
const types: type = @import("types.zig");

pub fn resolveAllIndex(class: pci.PCIClass, vendor: pci.PCIVendor) struct { ?u8, ?u8 } {
    return .{
        @call(.always_inline, resolveIndexByClass, .{
            class
        }),
        @call(.always_inline, resolveIndexByVendor, .{
            vendor
        }),
    };
}

pub fn resolveIndexByClass(class: pci.PCIClass) ?u8 {
    const index = switch(class) {
        .storage => types.PhysIoClass.storage,
        .network => types.PhysIoClass.network,
        .display => types.PhysIoClass.display,
        .multimedia => types.PhysIoClass.multimedia,
        .bridge => types.PhysIoClass.bridge,
        .sbus => types.PhysIoClass.sbus,
        _ => return null,
    };
    return @intFromEnum(index);
}

pub fn resolveIndexByVendor(vendor: pci.PCIVendor) ?u8 {
    const index = switch(vendor) {
        .intel => types.PhysIoVendor.intel,
        .amd => types.PhysIoVendor.amd,
        .nvidia => types.PhysIoVendor.nvidia,
        .broadcom => types.PhysIoVendor.broadcom,
        .realtek => types.PhysIoVendor.realtek,
        .qualcomm => types.PhysIoVendor.qualcomm,
        .marvell => types.PhysIoVendor.marvell,
        .vmware => types.PhysIoVendor.vmware,
        .virtio => types.PhysIoVendor.virtio,
        .virtualbox => types.PhysIoVendor.virtualbox,
        .qemu => types.PhysIoVendor.qemu,
        _ => return null,
    };
    return @intFromEnum(index);
}
