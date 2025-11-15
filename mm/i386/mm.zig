// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mm.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const mmu: type = @import("mmu.zig");
const page: type = @import("page.zig");
const types: type = @import("types.zig");

pub const AllocPage_T: type = types.AllocPage_T;
pub const AllocPageErr_T: type = types.AllocPageErr_T;

pub const mmu_init = mmu.mmu_init;
pub const alloc_page = page.alloc_page;
pub const alloc_pages = page.alloc_pages;
pub const alloc_zeroed_page = page.alloc_zeroed_page;
pub const free_page = page.free_page;
pub const free_pages = page.free_pages;

