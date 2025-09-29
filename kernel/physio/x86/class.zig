// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: class.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const PCIClassesIDs_T: type = @import("types.zig").PCIClassesIDs_T;

pub fn physIoClassSubClass(class: PCIClassesIDs_T, sub: u8, prog: u8) []const u8 {
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
