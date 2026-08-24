// ┌────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: codes.zig  │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const ArchManifest_T: type = @import("root").interfaces.arch.ArchManifest_T;

pub const __SaturnArchManifests__ = [_]ArchManifest_T {
    .{
        .target = .i386,
        .arch = @import("kernel/arch/i386/i386.zig"),
        .exposed = &[_]ArchManifest_T.ContainerExposed_T {
            ArchManifest_T.ContainerExposed_T {
                .name = "entry",
                .container = @import("kernel/entries/i386/entry.zig"),
            },

            ArchManifest_T.ContainerExposed_T {
                .name = "init",
                .container = @import("kernel/init/i386/init.zig"),
            },

            ArchManifest_T.ContainerExposed_T {
                .name = "interrupts",
                .container = @import("kernel/interrupts/i386/interrupts.zig"),
            },

            ArchManifest_T.ContainerExposed_T {
                .name = "physio",
                .container = @import("kernel/physio/i386/physio.zig"),
            },

            ArchManifest_T.ContainerExposed_T {
                .name = "mm",
                .container = @import("mm/i386/mm.zig"),
            },

            ArchManifest_T.ContainerExposed_T {
                .name = "lib",
                .container = struct {
                    pub const kernel: type = @import("lib/saturn/kernel/arch/i386/lib.zig");
                    pub const userspace: type = @import("lib/saturn/userspace/i386/lib.zig");
                },
            },
        },
    },

    .{
        .target = .amd64,
        .arch = @import("kernel/arch/amd64/amd64.zig"),
    },

    .{
        .target = .arm,
        .arch = @import("kernel/arch/arm/arm.zig"),
    },

    .{
        .target = .riscv64,
        .arch = @import("kernel/arch/riscv64/riscv64.zig"),
    },

    .{
        .target = .avr,
        .arch = @import("kernel/arch/avr/avr.zig"),
    },

    .{
        .target = .xtensa,
        .arch = @import("kernel/arch/xtensa/xtensa.zig"),
    },
};
