// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: page.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("root").config;
const types: type = @import("types.zig");

const phys_address_start: u32 = config.kernel.options.kernel_phys_address;
const virtual_address_start: u32 = config.kernel.options.kernel_virtual_address;
const arch_section_text_loader = arch.arch_section_text_loader;
const arch_section_data_loader = arch.arch_section_data_loader;

pub const phys_address_opensaturn_start = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_start", // in linker
});
pub const phys_address_opensaturn_end = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_end", // in linker
});
pub const phys_arch_start = @extern(*anyopaque, .{
    .name = "phys_arch_start",
});
pub const phys_arch_data_start = @extern(*anyopaque, .{
    .name = "phys_arch_data_start", // in linker
});
pub const phys_arch_end = @extern(*anyopaque, .{
    .name = "phys_arch_end", // in linker
});

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
        .table_addr = 0, // Phys address
    },
} ** 1024;

pub var kernel_page_table: [1024]types.PageTableEntry_T align(4096) = [_]types.PageTableEntry_T {
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

comptime {
    @export(&kernel_page_dir[0], .{
        .name = "kernel_page_dir",
        .section = arch_section_data_loader,
    });
    @export(&kernel_page_table[0], .{
        .name = "kernel_page_table",
        .section = arch_section_data_loader,
    });
}

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

pub fn mmu_decode_virtual(virtual: u32) struct { u10, u10, u12 } {
    return .{
        @intCast((virtual >> 22) & 0x3FF),
        @intCast((virtual >> 12) & 0x3FF),
        @intCast(virtual & 0xFFF),
    };
}
