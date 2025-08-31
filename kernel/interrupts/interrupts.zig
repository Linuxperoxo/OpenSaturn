// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interrupts.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

// --- SATURN ARCH INTERRUPTS ---
pub const ArchInterrupts = [_]type {
    @import("x86/x86_interrupts.zig"),
    @import("x86_64/x86_64_interrupts.zig"),
    @import("arm/arm_interrupts.zig"),
    @import("avr/avr_interrupts.zig"),
    @import("xtensa/xtensa_interrupts.zig"),
};
