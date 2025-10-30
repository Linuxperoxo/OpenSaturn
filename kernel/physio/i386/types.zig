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
    brother: ?*@This(),
    status: enum {
        missing,
        active,
    },
    flags: packed struct(u8) {
        find: u1, // podemos achar esse dispositivo quando o search e usado
        hit: u2, // quantidade de hits no sync, quando 0 considerado como missing
        link: u1, // quando um search atingiu esse device
        save: u1, // salva informacoes do dispositivo para quando for ativado novamente
        reserved: u3 = 0,
    },
};

pub const PhysIoErr_T: type = error {
    Missing,
    NonFound,
    NoFind,
};
