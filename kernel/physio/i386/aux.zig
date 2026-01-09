// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const pci: type = if(!builtin.is_test) @import("root").code.lib.kernel.io.pci else @import("test/types.zig");
const types: type = @import("types.zig");

pub fn resolve_all_index(class: pci.PCIClass_T, vendor: pci.PCIVendor_T) struct { ?u8, ?u8 } {
    return .{
        @call(.always_inline, resolve_index_by_class, .{
            class
        }),
        @call(.always_inline, resolve_index_by_vendor, .{
            vendor
        }),
    };
}

pub fn resolve_index_by_class(class: pci.PCIClass_T) ?u8 {
    const index = switch(class) {
        .storage => types.PhysIoClass_T.storage,
        .network => types.PhysIoClass_T.network,
        .display => types.PhysIoClass_T.display,
        .multimedia => types.PhysIoClass_T.multimedia,
        .bridge => types.PhysIoClass_T.bridge,
        .sbus => types.PhysIoClass_T.sbus,
        _ => return null,
    };
    return @intFromEnum(index);
}

pub fn resolve_index_by_vendor(vendor: pci.PCIVendor_T) ?u8 {
    const index = switch(vendor) {
        .intel => types.PhysIoVendor_T.intel,
        .amd => types.PhysIoVendor_T.amd,
        .nvidia => types.PhysIoVendor_T.nvidia,
        .broadcom => types.PhysIoVendor_T.broadcom,
        .realtek => types.PhysIoVendor_T.realtek,
        .qualcomm => types.PhysIoVendor_T.qualcomm,
        .marvell => types.PhysIoVendor_T.marvell,
        .vmware => types.PhysIoVendor_T.vmware,
        .virtio => types.PhysIoVendor_T.virtio,
        .virtualbox => types.PhysIoVendor_T.virtualbox,
        .qemu => types.PhysIoVendor_T.qemu,
        _ => return null,
    };
    return @intFromEnum(index);
}
