// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

pub const ConfigVendors: type = enum {
    nvidia,
    qemu,
    intel,
    amd,
};

pub const FbErr: type = error {
    ExpectNoNFound,
    InvalidCommand,
    UnexpectedData,
    MissingDevice,
};

pub const FbCommands: type = enum(usize) {
    color = 0x80,
    clear = 0x70,
    move = 0x60,
    put = 0x50,
    load = 0x40,
    _,
};
