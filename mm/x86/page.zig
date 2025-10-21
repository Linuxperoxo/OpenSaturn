// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: page.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("root").config;
const types: type = @import("types.zig");

const section_text_loader = arch.sections.section_text_loader;
const section_data_loader = arch.sections.section_data_loader;

const phys_address_start: u32 = config.kernel.options.kernel_phys_address;
const virtual_address_start: u32 = config.kernel.options.kernel_virtual_address;

// Antes de conseguir adicionar todos os os segmentos do kernel
// o bootloader precisa ser arrumado, ja que arquivos grandes
// ele nao consegue carregar por completo, causando uma falha
// no carregamento completo
pub const kernel_index = [_]u10 {
    @intCast(config.kernel.options.kernel_text_virtual >> 22), // .text
    @intCast(config.kernel.options.kernel_vmem_virtual >> 22), // tmp allocs
    @intCast(config.kernel.options.kernel_page_td_virtual >> 22), // kernel page_table and page_directory
    @intCast(config.kernel.options.kernel_stack_base_virtual >> 22), // kernel stack
    @intCast(config.kernel.options.kernel_data_virtual >> 22), // .data, .rodata
    @intCast(config.kernel.options.kernel_paged_memory_virtual >> 22), // 
    @intCast(config.kernel.options.kernel_mmio_virtual >> 22), // kernel mmio
};

// NOTE: Finalizar map de memoria para o restante

pub const KernelPageIndex: type = enum(u8) {
    text = 0,
    vmem = 1,
    td = 2,
    stack = 3,
    data = 4,
    paged = 5,
    mmio = 6,
};

pub var kernel_page_dir: [1024]types.PageDirEntry_T align(4) = r: {
    var page_dir = [_]types.PageDirEntry_T {
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
            .table_phys = 0,
        },
    } ** 1024;
    for(0..kernel_index.len) |i| {
        page_dir[kernel_index[i]].avail = @intCast(0b0111 & i); // index to kernel_page_table;
        page_dir[kernel_index[i]].reserved = @intCast((i >> 3) & 0b0001); // index to kernel_page_table bit most sig
    }
    break :r page_dir;
};

pub var kernel_page_table: [kernel_index.len][1024]types.PageTableEntry_T align(4096) = [_][1024]types.PageTableEntry_T {
    [_]types.PageTableEntry_T {
        types.PageTableEntry_T {
            .present = 0,
            .rw = 0,
            .user = 0,
            .accessed = 0,
            .dirty = 0,
            .reserved = 0,
            .phys = 0,
        },
    } ** 1024
} ** kernel_index.len;

// page_table temporaria apenas para mapear o endereco fisico atual para o mesmo endeco virtual,
// isso e importante, ja que antes de pular para o endereco virtual apenas, precisamos continuar
// onde estamos, no caso 0x01000000, entao precisamos mapear o endereco virtual 0x01000000 para o
// mesmo endereco fisico, depois essa tabela de paginas nunca mais sera usada
pub var bootstrap_page_table: [1024]types.PageTableEntry_T align(4096) = [_]types.PageTableEntry_T {
    types.PageTableEntry_T {
        .present = 0,
        .rw = 1,
        .user = 0,
        .accessed = 0,
        .dirty = 0,
        .reserved = 0,
        .phys = 0,
    },
} ** 1024;

comptime {
    @export(&kernel_page_dir, .{
        .name = "kernel_page_dir",
        .section = section_data_loader,
    });
    @export(&kernel_page_table, .{
        .name = "kernel_page_table",
        .section = section_data_loader,
    });
    @export(&bootstrap_page_table, .{
        .name = "bootstrap_page_table",
        .section = section_data_loader,
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
