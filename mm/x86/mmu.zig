// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mmu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("root").config;
const page: type = @import("page.zig");
const types: type = @import("types.zig");

// sections []const u8
const arch_section_text_loader = arch.arch_section_text_loader;
const arch_section_data_loader = arch.arch_section_data_loader;

// opensaturn config
const kernel_phys_address = config.kernel.options.kernel_phys_address;
const kernel_virtual_address = config.kernel.options.kernel_virtual_address;
const kernel_arch_virtual_address = config.kernel.options.kernel_arch_virtual_address;
const kernel_page_size = config.kernel.options.kernel_page_size;
const kernel_stack_base_virtual_address = config.kernel.options.kernel_stack_base_virtual_address;
const kernel_stack_base_phys_addres = config.kernel.options.kernel_stack_base_phys_address;
const kernel_stack_size = config.kernel.options.kernel_stack_size;

// opensaturn real code start/end
const phys_address_opensaturn_start = page.phys_address_opensaturn_start; // in linker
const phys_address_opensaturn_end = page.phys_address_opensaturn_end; // in linker

// linker
const phys_arch_start = page.phys_arch_start;
const phys_arch_data_start = page.phys_arch_data_start;
const phys_arch_end = page.phys_arch_end;

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
// tutalmente para usar endereco virtual

pub fn mmu_init() linksection(arch_section_text_loader) callconv(.c) void {
    const total_of_pages_arch_sections: u32 = @call(.always_inline, resolve_num_of_pages, .{
        @intFromPtr(phys_arch_end) - @intFromPtr(phys_arch_start)
    });
    const total_of_pages_opensaturn_sections: u32 = @call(.always_inline, resolve_num_of_pages, .{
        @intFromPtr(phys_address_opensaturn_end) - @intFromPtr(phys_address_opensaturn_start)
    });
    const total_of_pages_stack: u32 = @call(.always_inline, resolve_num_of_pages, .{
        kernel_stack_size
    });
    const aux: type = opaque {
        pub fn map(total_pages: u32, base: u32, phys: ?u32) void {
            for(0..total_pages) |i|  {
                const dir, const table, _ = @call(.always_inline, page.mmu_decode_virtual, .{
                    base + (kernel_page_size * i)
                });
                page.kernel_page_dir[dir].present = 1;
                page.kernel_page_dir[dir].rw = 1;
                page.kernel_page_dir[dir].table_addr = @intCast(@intFromPtr(&page.kernel_page_table) >> 12);

                page.kernel_page_table[table].present = 1;
                page.kernel_page_table[table].rw = 1;
                page.kernel_page_table[table].phys = @intCast((phys orelse base + (kernel_page_size * i)) >> 12);
            }
        }
    };
    @call(.always_inline, aux.map, .{
        total_of_pages_arch_sections, @intFromPtr(phys_arch_start), null
    });
    @call(.always_inline, aux.map, .{
        total_of_pages_opensaturn_sections, @intFromPtr(phys_address_opensaturn_start), null
    });
    @call(.always_inline, aux.map, .{
        total_of_pages_stack, kernel_stack_base_virtual_address, kernel_stack_base_phys_addres
    });
    asm volatile(
        \\ movl (%esp), %edi
        \\ andl $0x00000FFF, %esp
        \\ orl %edx, %esp
        \\ movl %eax, %cr3
        \\ movl %cr0, %eax
        \\ orl %[cr0_paging_bit], %eax
        \\ movl %eax, %cr0
        \\ movl (%esp), %esi
        :
        :[_] "{eax}" (&page.kernel_page_dir),
         [_] "{edx}" (kernel_stack_base_virtual_address),
         [cr0_paging_bit] "i" (cr0_paging_bit)
        : .{
            .ecx = true,
            .edi = true,
            .esi = true,
        }
    );
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

//pub fn mmu_init() linksection(arch_section_text_loader) callconv(.c) void {
    // TODO: Mandar IDT GDT para o endereco 0xF000_0000

    //@call(.always_inline, gdt_remap_to_virtual, .{});
    //@call(.always_inline, idt_remap_to_virtual, .{});

    //@call(.always_inline, map_arch_section_data_to_virtual, .{});
    //@call(.always_inline, map_kernel_section_to_virtual, .{});

    //asm volatile(
    //    \\ movl %eax, %cr3
    //    \\ movl %cr0, %eax
    //    \\ orl %[paging_bit], %eax
    //    \\ movl %eax, %cr0
    //    :
    //    :[_] "{eax}" (&page.kernel_page_dir),
    //     [_] "{ebx}" (&page.kernel_page_table),
    //     [_] "{ecx}" (page.phys_address_opensaturn_start),
    //     [paging_bit] "i" (cr0_paging_bit)
    //);
//}


fn map_arch_section_data_to_virtual() void {
    
}

fn map_kernel_section_to_virtual() void {

}

fn gdt_remap_to_virtual() void {
    const gdt_struct_phys_address: u32 = @intFromPtr(@extern(*anyopaque, .{
        .name = "gdt_struct"
    }));
    const offset: u12 = @intCast(
        gdt_struct_phys_address & 0xFFF
    );
    _ = offset;
    asm volatile(
        \\ 
        :
        :
    );
}

fn idt_remap_to_virtual() void {
    const idt_struct_phys_address = @extern(*anyopaque, .{
        .name = "idt_struct"
    });
    const offset: u12 = @intCast(
        idt_struct_phys_address & 0xFFF
    );
    _ = offset;
    asm volatile(
        \\
        :
        :
    );
}
