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
    interfaces.arch.ArchDescription_T,
    interfaces.module.ModuleDescription_T,
};

pub const DeclsOffset_T: type = enum {
    arch,
    module,
};

pub fn container_decl_exist(comptime container: type, comptime decl: DeclsOffset_T) bool {
    return @hasDecl(container, saturn_especial_decls[
        @intFromEnum(decl)
    ]);
}

pub fn container_decl_type(comptime container: type, comptime decl: DeclsOffset_T) bool {
    return container == saturn_especial_decls_types[
        @intFromEnum(decl)
    ];
}

pub fn what_is_decl(comptime decl: DeclsOffset_T) []const u8 {
    return saturn_especial_decls[
        @intFromEnum(decl)
    ];
}

pub fn what_is_decl_type(comptime decl: DeclsOffset_T) type {
    return saturn_especial_decls_types[
        @intFromEnum(decl)
    ];
}
