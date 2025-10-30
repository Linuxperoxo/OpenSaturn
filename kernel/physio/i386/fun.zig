// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fun.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const pci: type = @import("root").kernel.io.pci;

const PhysIo_T: type = types.PhysIo_T;
const PhysIoErr_T: type = types.PhysIoErr_T;
const PCIClass_T: type = pci.PCIClass_T;
const PCIVendor_T: type = pci.PCIVendor_T;
const PCIPhysIo_T: type = pci.PCIPhysIo_T;

pub fn physIoSearch(
    class: PCIClass_T,
    vendor: PCIVendor_T,
    subclass: ?@TypeOf(
        @FieldType(PCIPhysIo_T, "subclass")
    ),
    deviceID: ?@TypeOf(
        @FieldType(PCIPhysIo_T, "deviceID")
    )
) PhysIoErr_T!PhysIo_T {

}

pub fn physIoRemap(phid: usize) PhysIoErr_T!void {

}

pub fn physIoSetIRQ(phid: usize) PhysIoErr_T!void {

}


