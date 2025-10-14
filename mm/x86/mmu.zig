// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mmu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;

const page: type = @import("page.zig");
const types: type = @import("types.zig");

const virtual_address_start = page.virtual_address_start;
const phys_address_start = page.phys_address_start;
const cr0_paging_bit: u32 = 0x01 << 31;

pub const arch_section_text_loader = arch.arch_section_text_loader;
pub const arch_section_data_loader = arch.arch_section_data_loader;

comptime {
    @export(&page.kernel_page_dir[0], .{
        .name = "kernel_page_dir",
        .section = arch_section_data_loader,
    });
    @export(&page.kernel_page_table[0], .{
        .name = "kernel_page_table",
        .section = arch_section_data_loader,
    });
}

pub fn mmu_init() linksection(arch_section_text_loader) callconv(.c) void {
    const page_dir_ptr = &page.kernel_page_dir[(virtual_address_start >> 22) & 0x3FF];
    const page_table_ptr = &page.kernel_page_table[(virtual_address_start >> 12) & 0x3FF];
    page_dir_ptr.present = 1;
    page_dir_ptr.table_addr = @intCast(@intFromPtr(&page.kernel_page_table[0])  >> 12);
    page_table_ptr.phys = phys_address_start >> 12;
    page_table_ptr.present = 1;
    asm volatile(
        \\ jmp .
        \\ movl %eax, %cr3
        \\ movl %cr0, %eax
        \\ orl %[paging_bit], %eax
        \\ movl %eax, %cr0
        :
        :[_] "{eax}" (&page.kernel_page_dir),
         [_] "{ebx}" (&page.kernel_page_table),
         [paging_bit] "i" (cr0_paging_bit),
    );
}
