// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mmu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("root").config;
const page: type = @import("page.zig");
const types: type = @import("types.zig");
const linker: type = @import("root").arch.linker;

// sections []const u8
const section_text_loader = arch.sections.section_text_loader;
const section_data_loader = arch.sections.section_data_loader;

// opensaturn config
const kernel_phys_address = config.kernel.options.kernel_phys_address;
const kernel_virtual_address = config.kernel.options.kernel_virtual_address;
const kernel_arch_virtual_address = config.kernel.options.kernel_arch_virtual_address;
const kernel_page_size = config.kernel.options.kernel_page_size;
const kernel_stack_base_virtual = config.kernel.options.kernel_stack_base_virtual;
const kernel_stack_base_phys_addres = config.kernel.options.kernel_stack_base_phys_address;
const kernel_stack_size = config.kernel.options.kernel_stack_size;

// opensaturn real code start/end
const phys_address_opensaturn_text_start = linker.phys_address_opensaturn_text_start; // in linker
const phys_address_opensaturn_text_end = linker.phys_address_opensaturn_text_end; // in linker
const phys_address_opensaturn_data_start = linker.phys_address_opensaturn_data_start;
const phys_address_opensaturn_data_end = linker.phys_address_opensaturn_data_end;

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
}

// preciso mapear tudo antes de dar jmp
// * precimo mapear endereco fisico para o mesmo endereco virtual
// por causa do eip por exemplo, mesma coisa para stack, mas isso
// vai ser temporario, depois que passa configurar isso podemos mudar
// totalmente para usar endereco virtual

pub fn mmu_init() linksection(section_text_loader) callconv(.c) void {
    @call(.always_inline, configure_bootstrap, .{}); // done!
    @call(.always_inline, configure_kernel_text, .{}); // done!
    @call(.always_inline, configure_kernel_data, .{}); // done?
    @call(.always_inline, configure_kernel_stack, .{}); // done!
    // TODO: gdt idt devem ir para .data do kernel, ja que a page_table de bootstrap
    // vai ser anulada apos memoria virtual estar configurada, ou seja, a primeira coisa
    // que vamos executar vai ser o init, mm, depois vamos configurar o gdt e o idt ja usando
    // memoria virtual
    asm volatile(
        // \\ movl $0xFFFF, (%esp) | debug
        // \\ movl (%esp), %edi | debug
        \\ andl $0x00000FFF, %esp
        \\ orl %edx, %esp
        \\ movl %eax, %cr3
        \\ movl %cr0, %eax
        \\ orl %[cr0_paging_bit], %eax
        \\ movl %eax, %cr0
        // \\ movl (%esp), %esi | debug
        // \\ movb $0xFF, 4095(%edx) | debug
        :
        :[_] "{eax}" (&page.kernel_page_dir),
         [_] "{edx}" (kernel_stack_base_virtual),
         [cr0_paging_bit] "i" (cr0_paging_bit),
        : .{
            .ecx = true,
        }
    );
}

fn configure_bootstrap() void {
    const total_of_pages_arch_sections: u32 = @call(.always_inline, resolve_num_of_pages, .{
        @intFromPtr(phys_i386_end) - @intFromPtr(phys_i386_start)
    });
    const bootstrap_page_dir_entry: *types.PageDirEntry_T = &page.kernel_page_dir[
        config.kernel.options.kernel_phys_address >> 22
    ];
    const bootstrap_page_table: *[1024]types.PageTableEntry_T = &page.bootstrap_page_table;
    bootstrap_page_dir_entry.present = 1;
    bootstrap_page_dir_entry.rw = 1;
    bootstrap_page_dir_entry.table_phys = @intCast(@intFromPtr(bootstrap_page_table) >> 12);
    for(0..total_of_pages_arch_sections) |i| {
        bootstrap_page_table[i].present = 1;
        bootstrap_page_table[i].rw = 1;
        bootstrap_page_table[i].phys = @intCast((@intFromPtr(phys_i386_start) + kernel_page_size * i) >> 12);
    }
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
        kernel_stack_base_phys_addres,
        page.KernelPageIndex.stack,
        @call(.always_inline, resolve_num_of_pages, .{
            (kernel_stack_base_phys_addres + kernel_stack_size) - kernel_stack_base_phys_addres
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

fn kernel_map(phys: u32, index: page.KernelPageIndex, pages: u32, rw: u1) void {
    const page_dir: *types.PageDirEntry_T = &page.kernel_page_dir[
        page.kernel_index[@intFromEnum(index)]
    ];
    const page_table: *[1024]types.PageTableEntry_T = &page.kernel_page_table[
        @as(u4, page_dir.avail) | (@as(u4, page_dir.reserved) << 3)
    ];
    page_dir.rw = rw;
    page_dir.present = 1;
    page_dir.table_phys = @intCast(@intFromPtr(page_table) >> 12);
    for(0..pages) |i| {
        page_table[i].rw = rw;
        page_table[i].present = 1;
        page_table[i].phys = @intCast((phys + kernel_page_size * i) >> 12);
    }
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
