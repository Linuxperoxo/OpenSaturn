// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: entries.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// --- SATURN ARCH ENTRIES ---
pub const ArchEntries = [_]type {
    @import("x86/entry.zig"),
    @import("x86_64/entry.zig"),
    @import("arm/entry.zig"),
    @import("avr/entry.zig"),
    @import("xtensa/entry.zig"),
};
