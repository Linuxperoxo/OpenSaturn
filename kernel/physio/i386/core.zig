// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig      │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const PhysIo_T: type = @import("types.zig").PhysIo_T;
const PhysIoErr_T: type = @import("types.zig").PhysIoErr_T;
const PhysIoInfo_T: type = @import("types.zig").PhysIoInfo_T;
const PCIClass_T: type = @import("root").kernel.io.pci.PCIClass_T;
const PCIVendor_T: type = @import("root").kernel.io.pci.PCIVendor_T;
const PhysLevel0_T: type = @import("types.zig").PhysLevel0_T;
const PhysLevel1_T: type = @import("types.zig").PhysLevel1_T;
const PhysLevel2_T: type = @import("types.zig").PhysLevel2_T;
const StepPhase: type = enum {
    Phys0,
    Phys1,
    Phys2,
};

var phys: PhysLevel0_T = .{
    .base = .{
        null
    } ** @typeInfo(PCIClass_T).@"enum".fields.len,
};

fn resolveIndexByClass(class: PCIClass_T) u8 {
    return switch(class) {
        .storage => 0,
        .network => 1,
        .display => 2,
        .multimedia => 3,
        .bridge => 4,
        .sbus => 5,
        _ => 6,
    };
}

fn resolveIndexByVendor(vendor: PCIVendor_T) u8 {
    return switch(vendor) {
        .intel => 0,
        .amd => 1,
        .nvidia => 2,
        .broadcom => 3,
        .realtek => 4,
        .qualcomm => 5,
        .marvell => 7,
        .vmware => 8,
        .virtio => 9,
        .virtualbox => 10,
        .qemu => 11,
        _ => 12,
    };
}

fn pathVerify(
    class: PCIClass_T,
    vendor: PCIVendor_T
) ?StepPhase {
    return r: {
        const classIndex = @call(.always_inline, &resolveIndexByClass, .{
            class
        });
        const vendorIndex = @call(.always_inline, &resolveIndexByVendor, .{
            vendor
        });
        if(phys.base[classIndex] == null) break :r StepPhase.Phys0;
        if(phys.base[classIndex].?.base[vendorIndex] == null) break :r StepPhase.Phys1;
        break :r null;
    };
}

pub fn register_physio(
    physio: PhysIo_T,
) PhysIoErr_T!void {
    return r: {
        const step = @call(.always_inline, &pathVerify, .{
            physio.device.class, physio.device.vendorID
        });
        sw: switch(step orelse break :r PhysIoErr_T.NonFound) {
            .Phys0 => {

            },

            .Phys1 => {

            },
            else => break :sw {},
        }
    };
}

pub fn search_physio() PhysIoErr_T!void {

}

pub fn tree_sync() void {

}

