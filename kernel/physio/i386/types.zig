// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const pci: type = if(!builtin.is_test) @import("root").kernel.io.pci else @import("test.zig");
const allocator: type = @import("allocator.zig");

const PCIPhysIo_T: type = pci.PCIPhysIo_T;
const PCIClass_T: type = pci.PCIClass_T;
const PCIVendor_T: type = pci.PCIVendor_T;

pub const PhysIo_T: type = struct {
    device: PCIPhysIo_T,
    // quantidade de retornos desse phys, isso e importante para que
    // o driver saiba se outro driver esta possivelmente usando o mesmo
    // phys
    refs: u32,
    brothers: u8,
    status: enum {
        missing,
        active,
    },
    flags: packed struct(u8) {
        find: u1, // podemos achar esse dispositivo quando o search e usado
        hit: u2, // quantidade de hits no sync, quando 0 considerado como missing
        link: u1, // quando um search atingiu esse device
        save: u1, // salva informacoes do dispositivo para quando for ativado novamente
        identified: u1, // phys identificado, ou seja, com vendor reconhecido
        reserved: u2 = 0,
    },
    private: *anyopaque,
};

pub const PhysIoInfo_T: type = struct {
    phys: PhysIo_T,
    brother: ?*@This(),
    older_brother: ?*@This(),
    next: ?*@This(),
    prev: ?*@This(),

    pub fn alloc_this() allocator.sba.AllocatorErr_T!*@This() {
        const slice = try @call(.never_inline, allocator.sba.alloc, .{
            @sizeOf(@This())
        });
        return @alignCast(@ptrCast(slice.ptr));
    }

    pub fn free_this(ptr: *@This()) allocator.sba.AllocatorErr_T!void {
        const slice: []u8 = @as([*]u8, @ptrCast(ptr))[0..@sizeOf(@This())];
        try @call(.never_inline, allocator.sba.free, .{
            slice
        });
    }
};

pub const PhysIoErr_T: type = error {
    Missing,
    NonFound,
    NoFind,
    UnableRegister,
    InternalError,
    UnidentifiedPhysError,
    UnidentifiedPhysClass,
    UnidentifiedPhysVendor,
    ImpossibleSearch,
    NoBrothers,
    NotAllBrothersCopied,
    OutMemoryForBrothers,
    ExpurgAnAlreadyExpurged,
};

pub const VendorRoot_T: type = struct {
    identified: ?*[
        @typeInfo(PCIVendor_T).@"enum".fields.len
    ]?*PhysIoInfo_T,
    unidentified: ?*PhysIoInfo_T, // ordenado por deviceID

    pub fn alloc_this_identified(self: *@This()) allocator.sba.AllocatorErr_T!void {
        const slice = try @call(.never_inline, allocator.sba.alloc, .{
            @sizeOf(
                [
                    @typeInfo(PCIVendor_T).@"enum".fields.len
                ]?*PhysIoInfo_T
            )
        });
        self.identified = @alignCast(@ptrCast(slice.ptr));
        for(0..self.identified.?.len) |i|
            self.identified.?[i] = null;
    }
};

pub const PhysIoClass_T: type = enum {
    storage,
    network,
    display,
    multimedia,
    bridge,
    sbus,
};

pub const PhysIoVendor_T: type = enum {
    intel,
    amd,
    nvidia,
    broadcom,
    realtek,
    qualcomm,
    marvell,
    vmware,
    virtio,
    virtualbox,
    qemu,
};
