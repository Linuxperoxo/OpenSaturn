// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mm.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const mmu: type = @import("mmu.zig");
const page: type = @import("page.zig");

pub const virtual_address_start = page.virtual_address_start;
pub const phys_address_start = page.phys_address_start;

pub const mmu_init = mmu.mmu_init;
pub const alloc_page = page.alloc_page;
pub const alloc_pages = page.alloc_pages;
pub const alloc_zeroed_page = page.alloc_zeroed_page;
pub const free_page = page.free_page;
pub const free_pages = page.free_pages;

