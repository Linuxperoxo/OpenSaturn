// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: options.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// NOTE: nao modifique esse codigo caso uma arch
// precise usar uma configuracao diferente, apenas
// coloque dentro de saturn.zig uma declaracao chamada
// de config dentro da struct da arch, esse codigo e
// responsavel por selecionar a configuracao:
//
// saturn.zig:133
// pub const kernel: type = if(!@hasDecl(SelectedArch, "config")) @import("config/kernel/config.zig") else
//       SelectedArch.config
// ;

// configuracoes default do kernel, pensado para arch como (i364, x64, ARM)

// phys
pub const kernel_phys_address: u32 = 0x0100_0000;
pub const kernel_stack_base_phys_address: u32 = 0x00F0_0000;

// virtual
pub const kernel_virtual_address: u32 = 0xC000_0000;

pub const kernel_text_virtual: u32 = 0xC000_0000;
pub const kernel_vmem_virtual: u32 = 0xE000_0000;
pub const kernel_page_td_virtual: u32 = 0xFC00_0000; // table | directory
pub const kernel_stack_base_virtual: u32 = 0xFD00_0000;
pub const kernel_data_virtual: u32 = 0xFE00_0000;
pub const kernel_arch_virtual: u32 = 0xFA00_0000;
pub const kernel_paged_memory_virtual: u32 = 0xF000_0000;
pub const kernel_mmio_virtual: u32 = 0xFFF0_0000;

// extra
pub const kernel_page_size: u32 = 0x1000;
pub const kernel_stack_size: u32 = kernel_page_size * 1;
