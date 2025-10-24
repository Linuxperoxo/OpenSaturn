// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: page.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("root").config;
const types: type = @import("types.zig");
const zone: type = @import("zone.zig");

const section_text_loader = arch.sections.section_text_loader;
const section_data_loader = arch.sections.section_data_loader;
const section_data_page_dir = arch.sections.section_data_page_dir;
const section_data_page_table = arch.sections.section_data_page_table;

const kernel_mmu_main = config.kernel.mem.virtual.kernel_mmu_main;
const kernel_page_size = config.kernel.options.kernel_page_size;

pub const kernel_index = [_]u32 {
    config.kernel.mem.virtual.kernel_text, // .text
    config.kernel.mem.virtual.kernel_stack_base, // kernel stack
    config.kernel.mem.virtual.kernel_mmu_main, // main kernel page_dir and page_table
    config.kernel.mem.virtual.kernel_data, // .data, .rodata
    config.kernel.mem.virtual.kernel_paged_memory, // zone_kernel
    config.kernel.mem.virtual.kernel_mmio, // kernel mmio
};

pub const KernelPageIndex: type = enum {
    text,
    stack,
    mmu,
    data,
    paged,
    mmio,
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
        page_dir[kernel_index[i] >> 22].avail = @intCast(0b0111 & i); // index to kernel_page_table;
        page_dir[kernel_index[i] >> 22].reserved = @intCast((i >> 3) & 0b0001); // index to kernel_page_table bit most sig
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

// TODO: kernel_page_dir e kernel_page_table devem ir para .data
// do kernel de alguma forma, e precisamos pegar o endereco fisico
// deles, talvez de para pegar o endereco fisico de cada um colocando
// cada um em uma section separada, e no linker so vamos precisar
// pegar o phys de onde inciar aquela section
comptime {
    @export(&kernel_page_dir, .{
        .name = "kernel_page_dir",
        .section = section_data_page_dir,
    });
    @export(&kernel_page_table, .{
        .name = "kernel_page_table",
        .section = section_data_page_table,
    });
    @export(&bootstrap_page_table, .{
        .name = "bootstrap_page_table",
        .section = section_data_loader,
    });
}

// sao usados somente para o alocador de paginas consiga manipular as paginas diretamente
pub const kernel_page_dir_virtual: *[1024]types.PageDirEntry_T = @ptrFromInt(kernel_mmu_main);
pub const kernel_page_table_virtual: *[kernel_index.len][1024]types.PageTableEntry_T = @ptrFromInt(kernel_mmu_main + @sizeOf(@TypeOf(kernel_page_dir)));

pub fn alloc_page() types.AllocPageErr_T!types.AllocPage_T {
    return r: {
        // tentamos alocar uma pagina na zone_kernel, em caso de pageout,
        // tantamos alocar na zone_high
        break :r zone.alloc_zone_page(
            .kernel,
        ) catch |err| switch(err) {
            types.AllocPageErr_T.OutPage => break :r zone.alloc_zone_page(
                .high,
            ),
            else => return err,
        };
    };
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
