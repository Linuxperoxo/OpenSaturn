// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: segments.zig │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// NOTE: nao modifique os enderecos desses arquivos, eles sao os enderecos defaults
// do kernel, apenas modifique se souber o que esta fazendo, isso pode fazer o kernel
// nem iniciar

// NOTE: em caso de uma nova arquitetura sendo colocada, voce pode colocar em saturn.zig,
// dentro da struct da arquitetura um membro chamado segments, apenas de um @import para
// o arquivo que tem as configuracacoes, fazendo isso voce ja vai poder usar no seu codigo
// @import("root").config.kernel.mem
//
//    pub const mem: type = if(cpu.segments == void) @import("config/kernel/segments.zig") else
//        SelectedArch.arch.segments
//    ;

pub const phys: type = @import("mem/phys.zig");
pub const virtual: type = @import("mem/virtual.zig");
