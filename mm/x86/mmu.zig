// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mmu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const page: type = @import("page.zig");

const kernel_page_dir = page.kernel_page_dir;
const kernel_page_table = page.kernel_page_table;
const cr0_paging_bit: u32 = 0x01 << 31;

pub fn mmu_init() void {
    asm volatile(
        \\ movl %eax, %cr3
        \\ movl %cr0, %eax
        \\ orl %[paging_bit], %eax
        \\ movl %eax, %cr0
        :
        :[_] "{eax}" (&kernel_page_dir),
         [paging_bit] "i" (cr0_paging_bit)
        : .{
            .eax = true,
        }
    );
}
