// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: identifier.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const PCIVendor_T: type = @import("types.zig").PCIVendor_T;
const PCIClasses_T: type = @import("types.zig").PCIClasses_T;

pub fn physIoVendorName(vendorID: PCIVendor_T) []const u8 {
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

pub fn physIoClassSubClass(class: PCIClasses_T, sub: u8, prog: u8) []const u8 {
    return switch(class) {
        .storage => switch(sub) {
            0x01 => "IDE Controller",
            0x06 => "SATA Controller",
            0x08 => "NVMe Controller",
            else => "Mass Storage",
        },

        .network => "Network Controller",

        .display => switch(sub) {
            0x00 => "VGA-Compatible Controller",
            0x02 => "3D Controller",
            else => "Display Controller",
        },

        .bridge => switch (sub) {
            0x00 => "Host Bridge",
            0x01 => "PCI-to-PCI Bridge",
            else => "Bridge Device",
        },

        .multimedia => switch (sub) {
            0x00 => "Multimedia Audio Controller",
            0x01 => "Multimedia Video Controller",
            0x02 => "Multimedia Audio-Video Controller",
            0x03 => "Multimedia Telephony Device",
            else => "Multimedia Device",
        },

        .sbus => switch (sub) {
            0x03 => switch (prog) {
                0x00 => "USB UHCI Controller",
                0x10 => "USB OHCI Controller",
                0x20 => "USB EHCI Controller",
                0x30 => "USB XHCI Controller",
                else => "USB Controller",
            },
            else => "Serial Bus Controller",
        },
        _ => "Unknown Device Class",
    };
}
