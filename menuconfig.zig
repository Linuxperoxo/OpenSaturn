// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: menuconfig.zig  │
// │               Author: Linuxperoxo               │
// └─────────────────────────────────────────────────┘

// possible values for modules:
//   - y: module code is integrated into the kernel
//   - n: module code is removed from the kernel

pub const __SaturnModulesMenuconfig__ = [_]struct { module: []const u8, value: u8, } {
    .{
        .module = "rootfs",
        .value = 'n',
    },

    .{
        .module = "devfs",
        .value = 'y',
    },
};
