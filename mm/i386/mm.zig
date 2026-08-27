// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mm.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const mmu: type = @import("mmu.zig");
const page: type = @import("page.zig");
const types: type = @import("types.zig");

pub const AllocPage: type = types.AllocPage;
pub const AllocPageErr: type = types.AllocPageErr;

pub const mmuInit = mmu.mmuInit;
pub const allocPage = page.allocPage;
pub const allocPages = page.allocPages;
pub const allocZeroedPage = page.allocZeroedPage;
pub const freePage = page.freePage;
pub const freePages = page.freePages;
