// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const pci: type = @import("root").__SaturnArchImpl__.lib.kernel.io.pci;
const allocator: type = @import("allocator.zig");

const PCIPhysIo: type = pci.PCIPhysIo;
const PCIClass: type = pci.PCIClass;
const PCIVendor: type = pci.PCIVendor;

pub const PhysIo: type = struct {
    device: PCIPhysIo,
    // quantidade de retornos desse phys, isso e importante para que
    // o driver saiba se outro driver esta possivelmente usando o mesmo
    // phys
    refs: u32,
    brothers: u8,
    events: struct {
        connect: ?*const fn(*PhysIo) void = null,
        disconnect: ?*const fn(*PhysIo) void = null,
    },
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

    // deve ter essa funcao para que o driver possa ele
    // mesmo liberar seu proprio PhysIo
    pub fn free(self: *@This()) PhysIoErr!void {
        return r: {
            @call(.always_inline, allocator.sba.freeTypeSingle, .{
                @This(), self
            }) catch break :r PhysIoErr.InternalError;
            break :r {};
        };
    }
};

pub const PhysIoInfo: type = struct {
    phys: *PhysIo,
    brother: ?*@This(),
    older_brother: ?*@This(),
    next: ?*@This(),
    prev: ?*@This(),
};

pub const PhysIoErr: type = error {
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
    ListenerCollision,
    NoNListener,
    AlwaysWaiting,
    NoNWaiting,
};

pub const VendorRoot: type = struct {
    identified: ?*[
        @typeInfo(PCIVendor).@"enum".fields.len
    ]?*PhysIoInfo,
    unidentified: ?*PhysIoInfo, // ordenado por device_id

    pub fn allocThisIdentified(self: *@This()) allocator.sba.AllocatorErr!void {
        const slice = try @call(.never_inline, allocator.sba.allocTypeSingle, .{
            [@typeInfo(PCIVendor).@"enum".fields.len]?*PhysIoInfo
        });
        self.identified = @alignCast(@ptrCast(slice.ptr));
        for(0..self.identified.?.len) |i|
            self.identified.?[i] = null;
    }
};

pub const PhysIoClass: type = enum {
    storage,
    network,
    display,
    multimedia,
    bridge,
    sbus,
};

pub const PhysIoVendor: type = enum {
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
