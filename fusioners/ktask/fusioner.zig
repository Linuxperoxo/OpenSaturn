// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fusioner.zig    │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const fusium: type = @import("root").interfaces.fusium;
const listener: type = @import("listener.zig");

pub const __SaturnFusiumDescription__: fusium.FusiumDescription_T = .{
    .name = "ktask",
    .author = "Linuxperoxo",
    .description = "General Purpose Ktask Implementation For OpenSaturn",
    .order = .after,
    .fusioner = @import("ktask.zig"),
    .init = &listener.ktask_install_listener,
    .arch = &[_]fusium.FusiumDescription_T.Target_T {
        .i386,
        .amd64,
        .arm,
        .riscv64
    },
    .flags = .{
        .blocked = 0,
    },
};
