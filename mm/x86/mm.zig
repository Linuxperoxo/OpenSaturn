// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mm.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const mmu: type = @import("core.zig");
const page: type = @import("page.zig");

pub const mmu_init = mmu.mmu_init;
pub const alloc_page = page.alloc_page;
pub const alloc_pages = page.alloc_pages;
pub const alloc_zeroed_page = page.zeroed_alloc;
pub const free_page = page.free_page;
pub const free_pages = page.free_pages;
