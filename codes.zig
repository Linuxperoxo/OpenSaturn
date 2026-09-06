// ┌────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: codes.zig  │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const ArchManifest: type = @import("root").interfaces.arch.ArchManifest;

pub const __SaturnArchManifests__ = [_]ArchManifest {
    .{
        .target = .i386,
        .arch = @import("kernel/arch/i386/i386.zig"),
        .exposed = &[_]ArchManifest.ContainerExposed {
            ArchManifest.ContainerExposed {
                .name = "entry",
                .container = @import("kernel/entry/i386/entry.zig"),
            },

            ArchManifest.ContainerExposed {
                .name = "init",
                .container = @import("kernel/init/i386/init.zig"),
            },

            ArchManifest.ContainerExposed {
                .name = "interrupts",
                .container = @import("kernel/interrupts/i386/interrupts.zig"),
            },

            ArchManifest.ContainerExposed {
                .name = "physio",
                .container = @import("kernel/physio/i386/physio.zig"),
            },

            ArchManifest.ContainerExposed {
                .name = "mm",
                .container = @import("mm/i386/mm.zig"),
            },

            ArchManifest.ContainerExposed {
                .name = "lib",
                .container = struct {
                    pub const kernel: type = @import("lib/kernel/arch/i386/lib.zig");
                    pub const userspace: type = @import("lib/userspace/i386/lib.zig");
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
