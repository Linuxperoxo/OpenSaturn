// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: page.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");

pub const virtual_address_start: usize = 0xC000_0000;
pub const phys_address_start: usize = 0x0010_0000;

pub var kernel_page_dir: [1024]types.PageDirEntry_T align(1024) = [_]types.PageDirEntry_T {
    types.PageDirEntry_T {
        .present = 0,
        .rw = 0,
        .user = 0,
        .write_thru = 0,
        .cache_dis = 0,
        .accessed = 0,
        .reserved = 0,
        .page_size = 0, // 4Kib
        .ignored = 0,
        .avail = 0,
        .table_addr = 0,
    },
} ** 1024;

pub var kernel_page_table: [1024]types.PageTableEntry_T align(1024) = [_]types.PageTableEntry_T {
    types.PageTableEntry_T {
        .present = 0,
        .rw = 0,
        .user = 0,
        .accessed = 0,
        .dirty = 0,
        .reserved = 0,
        .phys = 0,
    },
} ** 1024;

pub fn alloc_page() types.AllocPage_T {

}

pub fn alloc_pages(_: usize) []types.AllocPage_T {

}

pub fn alloc_zeroed_page() []types.AllocPage_T {

}

pub fn free_page(_: *types.AllocPage_T) void {

}

pub fn free_pages(_: []types.AllocPage_T) void {

}
