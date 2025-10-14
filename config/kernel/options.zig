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

pub const kernel_phys_address: comptime_int = 0x0100_0000;
pub const kernel_virtual_address: comptime_int = 0xC000_0000;
pub const kernel_page_size: comptime_int = 0x1000;
pub const kernel_arch_virtual_address: comptime_int = 0xF000_0000;
pub const kernel_stack_base_virtual_address: comptime_int = 0xE00F_0000;
pub const kernel_stack_base_phys_address: comptime_int = 0x00F0_0000;
pub const kernel_stack_size: comptime_int = kernel_page_size * 1;
