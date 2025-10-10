// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: decls.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;

pub const saturn_especial_decls = [_][]const u8 {
    "__SaturnArchDescription__", // Descreve uma arch para o kernel
    "__SaturnModuleDescription__", // Descreve um modulo para o kernel
};

pub const saturn_especial_decls_types = [_]type {
    interfaces.arch.ArchDescription,
    interfaces.module.ModuleDescription_T,
};

pub const DeclsOffset_T: type = enum(u1) {
    arch = 0,
    module = 1,
};

