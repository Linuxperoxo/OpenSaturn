// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fusioner.zig    │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const fusium: type = @import("root").interfaces.fusium;
const main: type = @import("main.zig");

pub const __SaturnFusiumDescription__: fusium.FusiumDescription_T = .{
    .name = "ktask",
    .author = "Linuxperoxo",
    .description = "General Purpose Ktask Implementation For OpenSaturn",
    .fusioner = @import("ktask.zig"),
    .init = &main.sched_init,
    .arch = &[_]fusium.FusiumDescriptionTarget_T {
        .i386,
        .amd64,
        .arm,
        .riscv64
    },
    .flags = .{
        .blocked = 0,
    },
};
