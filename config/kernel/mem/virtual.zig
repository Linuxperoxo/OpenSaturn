// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: virtual.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const kernel_text: u32 = 0xC000_0000;
pub const kernel_stack_base: u32 = 0xFFC0_0000;
pub const kernel_mmu_main: u32 = 0xDFC0_0000;
pub const kernel_data: u32 = 0xE000_0000;
pub const kernel_paged_memory: u32 = 0xF000_0000;
pub const kernel_mmio: u32 = 0xFD00_0000;
