// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: memory.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo contem alocadores de
// memory independentes, ou seja, nao
// depende de forma alguma da implementacao
// mm da arquitetura

pub const soa: type = @import("soa/soa.zig");

pub fn kmalloc(comptime T: type, _: u32) anyerror![]T {
    var slice: []T = undefined;
    return slice[0..1];
}
