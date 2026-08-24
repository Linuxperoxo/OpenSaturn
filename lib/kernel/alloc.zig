// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: alloc.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Alocadores de alto nivel construidos sobre o
// gerenciador de paginas fornecido pela arquitetura.

pub const soa: type = @import("alloc/soa.zig");
pub const sba: type = @import("alloc/sba.zig");

pub fn kmalloc(comptime T: type, _: u32) anyerror![]T {
    var slice: []T = undefined;
    return slice[0..1];
}
