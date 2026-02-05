// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

pub const ConfigVendors_T: type = enum {
    nvidia,
    qemu,
    intel,
    amd,
};

pub const FbErr_T: type = error {
    ExpectNoNFound,
};
