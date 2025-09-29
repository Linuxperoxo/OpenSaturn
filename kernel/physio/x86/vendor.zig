// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vendor.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const PCIVendorIDs_T: type = @import("types.zig").PCIVendorIDs_T;

pub fn physIoVendorName(vendorID: PCIVendorIDs_T) []const u8 {
    return switch(vendorID) {
        .intel => "Intel Corporation",
        .amd => "Advanced Micro Devices, Inc. (AMD)",
        .nvidia => "NVIDIA Corporation",
        .broadcom => "Broadcom Inc.",
        .realtek => "Realtek Semiconductor Co., Ltd.",
        .qualcomm => "Qualcomm Atheros",
        .marvell => "Marvell Technology Group Ltd.",
        .vmware => "VMware, Inc.",
        .virtio => "Red Hat, Inc. (Virtio)",
        .virtualbox => "Oracle Corporation (VirtualBox)",
        .qemu => "QEMU Project",
        _ => "Unknown Vendor",
    };
}
