// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: alloc.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Alocadores de alto nivel construidos sobre o
// gerenciador de paginas fornecido pela arquitetura.

pub const soa: type = @import("alloc/soa.zig");
pub const sba: type = @import("alloc/sba.zig");
