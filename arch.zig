// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: arch.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// --- SATURN ARCH ---
pub const SupportedArch = [_]type {
    @import("kernel/arch/x86/x86.zig"),
    @import("kernel/arch/x86_64/x86_64.zig"),
    @import("kernel/arch/arm/arm.zig"),
    @import("kernel/arch/avr/avr.zig"),
};

