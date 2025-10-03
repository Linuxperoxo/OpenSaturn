// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const pci: type = @import("root").kernel.io.pci;

const PCIPhysIo_T: type = pci.PCIPhysIo_T;
const PCIClass_T: type = pci.PCIClass_T;
const PCIVendor_T: type = pci.PCIVendor_T;

pub const PhysIo_T: type = struct {
    device: PCIPhysIo_T,
};

pub const PhysIoInfo_T: type = struct {
    phys: PhysIo_T,
    status: Status_T,

    pub const Status_T: type = enum {
        missing,
        active,
        working
    };
};

pub const PhysIoErr_T: type = error {
    Missing,
    NonFound,
};

pub const PhysLevel0_T: type = struct {
    base: [
        @typeInfo(PCIClass_T).@"enum".fields.len
    ]?*PhysLevel1_T,
};

pub const PhysLevel1_T: type = struct {
    base: ?*[
        @typeInfo(PCIVendor_T).@"enum".fields.len
    ]?*PhysLevel2_T,
};

pub const PhysLevel2_T: type = struct {
    base: ?*[
        @typeInfo(PCIVendor_T).@"enum".fields.len
    ]?*PhysIoInfo_T,
};

