// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: segments.zig │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// NOTE: nao modifique os enderecos desses arquivos, eles sao os enderecos defaults
// do kernel, apenas modifique se souber o que esta fazendo, isso pode fazer o kernel
// nem iniciar

pub const phys: type = @import("mem/phys.zig");
pub const virtual: type = @import("mem/virtual.zig");
