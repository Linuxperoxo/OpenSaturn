// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: arch.zig      │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

// --- SATURN ARCH SUPPORTS ---
pub const ArchSupports = [_]type {
    @import("x86/x86.zig"),
    @import("x86_64/x86_64.zig"),
    @import("arm/arm.zig"),
    @import("avr/avr.zig"),
    @import("xtensa/xtensa.zig"),
};
