// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mmu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const page: type = @import("page.zig");
const types: type = @import("types.zig");

const virtual_address_start = page.virtual_address_start;
const phys_address_start = page.phys_address_start;
const cr0_paging_bit: u32 = 0x01 << 31;

comptime {
    @export(&page.kernel_page_dir[0], .{
        .name = "kernel_page_dir",
        .section = ".x86.arch.data",
    });
    @export(&page.kernel_page_table[0], .{
        .name = "kernel_page_table",
        .section = ".x86.arch.data",
    });
}

pub fn mmu_init() callconv(.c) void {
    const opensaturn_img_size = asm volatile(
        \\ movl $AtlasImgSize, %eax
        : [_] "={eax}" (-> u32)
    );
    asm volatile(
        \\ jmp .
        :
        :[_] "{eax}" (opensaturn_img_size)
    );
    const page_dir_ptr = &page.kernel_page_dir[(virtual_address_start >> 22) & 0x3FF];
    const page_table_ptr = &page.kernel_page_table[(virtual_address_start >> 12) & 0x3FF];
    page_dir_ptr.present = 1;
    page_dir_ptr.table_addr = @intCast(@intFromPtr(&page.kernel_page_table[0])  >> 12);
    page_table_ptr.phys = phys_address_start >> 12;
    page_table_ptr.present = 1;
    asm volatile(
        \\ movl %eax, %cr3
        \\ movl %cr0, %eax
        \\ orl %[paging_bit], %eax
        \\ movl %eax, %cr0
        :
        :[_] "{eax}" (&page.kernel_page_dir),
         [paging_bit] "i" (cr0_paging_bit)
        : .{
            .eax = true,
        }
    );
}
