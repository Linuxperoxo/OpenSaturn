// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: phys.zig    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

pub const kernel_phys: u32 = 0x0010_0000;
pub const kernel_stack_base: u32 = 0x00F0_0000;
pub const kernel_paged_memory: u32 = 0x0100_0000;
pub const kernel_mmio: u32 = 0x000A_0000;
