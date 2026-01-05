// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: codes.zig  │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const types: type = @import("kernel/ar/types.zig");

pub const __SaturnTargets__: types.Targets_T = .{
    .@"i386" = .{
        .arch = @import("kernel/arch/i386/i386.zig"),
        .entry = @import("kernel/entries/i386/entry.zig"),
        .init = @import("kernel/init/i386/init.zig"),
        .interrupts = @import("kernel/interrupts/i386/interrupts.zig"),
        .physio = @import("kernel/physio/i386/physio.zig"),
        .mm = @import("mm/i386/mm.zig"),
        .lib = .{
            .kernel = @import("lib/saturn/kernel/arch/i386/lib.zig"),
            .userspace = @import("lib/saturn/userspace/i386/lib.zig"),
        },
    },

    .amd64 = .{
        .arch = @import("kernel/arch/amd64/amd64.zig"),
        .entry = @import("kernel/entries/amd64/entry.zig"),
        .interrupts = @import("kernel/interrupts/amd64/interrupts.zig"),
        .mm = @import("mm/amd64/mm.zig"),
        .lib = .{
            .kernel = @import("lib/saturn/kernel/arch/amd64/lib.zig"),
            .userspace = @import("lib/saturn/userspace/amd64/lib.zig"),
        },
    },

    .arm = .{
        .arch = @import("kernel/arch/arm/arm.zig"),
        .entry = @import("kernel/entries/arm/entry.zig"),
    },

    .riscv64 = .{
        .arch = @import("kernel/arch/riscv64/riscv64.zig"),
        .entry = @import("kernel/entries/arm/entry.zig"),
    },
    
    .avr = .{
        .arch = @import("kernel/arch/avr/avr.zig"),
        .entry = @import("kernel/entries/avr/entry.zig"),
    },
    
    .xtensa = .{
        .arch = @import("kernel/arch/xtensa/xtensa.zig"),
        .entry = @import("kernel/entries/xtensa/entry.zig"),
    },
};
