// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mmu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("root").config;
const page: type = @import("page.zig");
const types: type = @import("types.zig");
const linker: type = @import("root").arch.linker;
const zone: type = @import("zone.zig");

// sections []const u8
const section_text_loader = arch.sections.section_text_loader;
const section_data_loader = arch.sections.section_data_loader;

// opensaturn mem phys config
const kernel_phys_address = config.kernel.mem.phys.kernel_phys;
const kernel_stack_base_phys_address = config.kernel.mem.phys.kernel_stack_base;

// opensauturn mem virtual config
const kernel_virtual_address = config.kernel.mem.virtual.kernel_text;
const kernel_stack_base_virtual = config.kernel.mem.virtual.kernel_stack_base;

// opensaturn options config
const kernel_page_size = config.kernel.options.kernel_page_size;
const kernel_stack_size = config.kernel.options.kernel_stack_size;

// opensaturn real code start/end
const phys_address_opensaturn_text_start = linker.phys_address_opensaturn_text_start; // in linker
const phys_address_opensaturn_text_end = linker.phys_address_opensaturn_text_end; // in linker
const phys_address_opensaturn_data_start = linker.phys_address_opensaturn_data_start;
const phys_address_opensaturn_data_end = linker.phys_address_opensaturn_data_end;
const phys_address_opensaturn_zone_kernel_start = linker.phys_address_zone_kernel_start;
const phys_address_opensaturn_mmu_start = linker.phys_address_opensaturn_mmu_start;
const phys_address_opensaturn_mmu_end = linker.phys_address_opensaturn_mmu_end;

// linker
const phys_i386_start = linker.phys_i386_start;
const phys_i386_data_start = linker.phys_i386_data_start;
const phys_i386_end = linker.phys_i386_end;

// cr0 paging bit
const cr0_paging_bit: u32 = 0x01 << 31;

comptime {
    if(kernel_page_size != 0x1000) {
        @compileError(
            "x86 expects page sizes to be 0x1000 bytes"
        );
    }
    // isso evita um overflow de pagina, como so temos apenas 1 page dir e 1
    // page table para o bootstrap identity mapping, nao pode ocorrer um overflow,
    // ou seja, usarmos o entry 1023 + 1 da page table, isso causa um overflow, e pode
    // ocorrer uma sobreescrita das paginas ja mapeadas
    if((1024 - ((kernel_phys_address >> 12) & 0x3FF)) <= 8) {
        @compileError(
            "kernel physical address too close to 4 MiB boundary — bootstrap identity mapping may overflow the page table"
        );
    }
    for(0..page.kernel_index.len) |i| {
        if(((page.kernel_index[i] >> 12) & 0x3FF) != 0) {
            @compileError(
                "kernel virtual regions must be aligned to 4MiB (page table index bits must be zero)"
            );
        }
        for(i..page.kernel_index.len - 1) |j| {
            if((page.kernel_index[i] >> 22 ) == (page.kernel_index[j + 1] >> 22)) {
                @compileError(
                    "there was an overprovision of virtual addresses in kernel_page_dir, check ur mem layout"
                );
            }
        }
    }
}

const kernel_page_dir_virtual = page.kernel_page_dir_virtual;
const kernel_page_table_virtual = page.kernel_page_table_virtual;

pub fn mmu_init() linksection(section_text_loader) callconv(.c) void {
    @call(.always_inline, configure_bootstrap, .{});
    @call(.always_inline, configure_kernel_text, .{});
    @call(.always_inline, configure_kernel_data, .{});
    @call(.always_inline, configure_kernel_stack, .{});
    @call(.always_inline, configure_kernel_mmu_phys_to_virt, .{});
    asm volatile(
        \\ andl $0x00000FFF, %esp
        \\ andl $0x00000FFF, %ebp
        \\ orl %edx, %esp
        \\ orl %edx, %ebp
        \\ movl %eax, %cr3
        \\ movl %cr0, %eax
        \\ orl %[cr0_paging_bit], %eax
        \\ movl %eax, %cr0
        :
        :[_] "{eax}" (&page.kernel_page_dir),
         [_] "{edx}" (kernel_stack_base_virtual),
         [cr0_paging_bit] "i" (cr0_paging_bit),
    );
    @call(.always_inline, configure_zone_kernel, .{}) catch unreachable;
}

fn configure_zone_kernel() types.ZoneErr_T!void {
    errdefer unreachable; // teoriacamente nunca vai dar erro, ja que e a primeira vez que usamos a zona
    try @call(.always_inline, zone.zone_resize, .{
        types.Zones_T.kernel, @intFromPtr(phys_address_opensaturn_zone_kernel_start), 32
    });
    try @call(.always_inline, zone.zone_reconf, .{
        types.Zones_T.kernel, 0b0000101
    });
    kernel_page_dir_virtual[page.kernel_index[@intFromEnum(page.KernelPageIndex.paged)] >> 22].present = 1;
    kernel_page_dir_virtual[page.kernel_index[@intFromEnum(page.KernelPageIndex.paged)] >> 22].rw = 1;
    kernel_page_dir_virtual[page.kernel_index[@intFromEnum(page.KernelPageIndex.paged)] >> 22].table_phys = @intCast(@intFromPtr(&page.kernel_page_table[
        @intFromEnum(page.KernelPageIndex.paged)
    ]) >> 12);
}

fn configure_bootstrap() void {
    // NOTE: phys_i386_start == config.kernel.mem.phys.kernel_phys
    const total_of_pages_arch_sections: u32 = @call(.always_inline, resolve_num_of_pages, .{
        @intFromPtr(phys_i386_end) - @intFromPtr(phys_i386_start)
    });
    const bootstrap_page_dir_entry: *types.PageDirEntry_T = &page.kernel_page_dir[
        // apenas 1 entry deve ser usada para o bootstrap, caso contrario, vai ter
        // sobreescrita da bootstrap_page_table, quanto menor os 10 bits para o
        // bootstrap_page_table melhor
        config.kernel.mem.phys.kernel_phys >> 22
    ];
    const bootstrap_page_table: *[1024]types.PageTableEntry_T = &page.bootstrap_page_table;
    var page_table_i: u32 = ((config.kernel.mem.phys.kernel_phys >> 12) & 0x3FF);
    for(0..total_of_pages_arch_sections) |_| {
        bootstrap_page_table[page_table_i].present = 1;
        bootstrap_page_table[page_table_i].rw = 1;
        bootstrap_page_table[page_table_i].phys = @intCast(((config.kernel.mem.phys.kernel_phys >> 12) & ~(@as(u16, 0x3FF))) | page_table_i);
        page_table_i += 1;
    }
    bootstrap_page_dir_entry.present = 1;
    bootstrap_page_dir_entry.rw = 1;
    bootstrap_page_dir_entry.table_phys = @intCast(@intFromPtr(bootstrap_page_table) >> 12);
}

fn configure_kernel_text() void {
    @call(.always_inline, kernel_map, .{
        @intFromPtr(phys_address_opensaturn_text_start),
        page.KernelPageIndex.text,
        @call(.always_inline, resolve_num_of_pages, .{
            @intFromPtr(phys_address_opensaturn_text_end) - @intFromPtr(phys_address_opensaturn_text_start)
        }),
        0
    });
}

fn configure_kernel_stack() void {
    @call(.always_inline, kernel_map, .{
        kernel_stack_base_phys_address,
        page.KernelPageIndex.stack,
        @call(.always_inline, resolve_num_of_pages, .{
            (kernel_stack_base_phys_address + kernel_stack_size) - kernel_stack_base_phys_address
        }),
        1
    });
}

fn configure_kernel_data() void {
    @call(.always_inline, kernel_map, .{
        @intFromPtr(phys_address_opensaturn_data_start),
        page.KernelPageIndex.data,
        @call(.always_inline, resolve_num_of_pages, .{
            @intFromPtr(phys_address_opensaturn_data_end) - @intFromPtr(phys_address_opensaturn_data_start)
        }),
        1
    });
}

fn configure_kernel_mmu_phys_to_virt() void {
    @call(.always_inline, kernel_map, .{
        @intFromPtr(&page.kernel_page_dir),
        page.KernelPageIndex.mmu,
        @call(.always_inline, resolve_num_of_pages, .{
            @intFromPtr(phys_address_opensaturn_mmu_end) - @intFromPtr(phys_address_opensaturn_mmu_start)
        }),
        1
    });
}

fn kernel_map(phys: u32, index: page.KernelPageIndex, pages: u32, rw: u1) void {
    // funcao espera que os enderecoes virtuais do kernel sejam alinhados a
    // 4Mib
    const page_dir: *types.PageDirEntry_T = &page.kernel_page_dir[
        page.kernel_index[@intFromEnum(index)] >> 22
    ];
    const page_table: *[1024]types.PageTableEntry_T = &page.kernel_page_table[
        @as(u4, page_dir.avail) | (@as(u4, page_dir.reserved) << 3)
    ];
    for(0..pages) |i| {
        page_table[i].rw = rw;
        page_table[i].present = 1;
        page_table[i].phys = @intCast((phys + kernel_page_size * i) >> 12);
    }
    page_dir.rw = rw;
    page_dir.present = 1;
    page_dir.table_phys = @intCast(@intFromPtr(page_table) >> 12);
}

fn resolve_num_of_pages(dif: u32) u32 {
    return asm volatile(
        // edx:eax / ecx
        // % = edx
        // / = eax
        \\ xorl %edx, %edx
        \\ leal -1(%eax,%ecx,), %eax
        \\ divl %ecx
        :[_] "={eax}" (-> u32)
        :[_] "{eax}" (dif),
         [_] "{ecx}" (kernel_page_size)
        : .{
            .edx = true,
        }
    );
}
