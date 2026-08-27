// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: decls.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;

pub const saturn_especial_decls = [_][]const u8 {
    "__SaturnArchDescription__", // Descreve uma arch para o kernel
    "__SaturnModuleDescription__", // Descreve um modulo para o kernel
    "__SaturnFusiumDescription__", // Descreve um fusioner para o kernel
    "__SaturnCSources__",
    "__SaturnCIncludes__",
};

pub const saturn_especial_decls_types = [_]type {
    interfaces.arch.ArchDescription,
    interfaces.module.ModuleDescription,
    interfaces.fusium.FusiumDescription,
    []const[]const u8,
    []const[]const u8,
};

pub const DeclsOffset: type = enum {
    arch,
    module,
    fusium,
    c_sources,
    c_includes,
};

pub fn declAccess(comptime container: type, comptime decl: DeclsOffset) @TypeOf(@field(container, whatIsDecl(decl))) {
    return @field(container, whatIsDecl(decl));
}

pub fn containerDeclExist(comptime container: type, comptime decl: DeclsOffset) bool {
    return @hasDecl(container, saturn_especial_decls[
        @intFromEnum(decl)
    ]);
}

pub fn containerDeclType(comptime container: type, comptime decl: DeclsOffset) bool {
    return container == saturn_especial_decls_types[
        @intFromEnum(decl)
    ];
}

pub fn whatIsDecl(comptime decl: DeclsOffset) []const u8 {
    return saturn_especial_decls[
        @intFromEnum(decl)
    ];
}

pub fn whatIsDeclType(comptime decl: DeclsOffset) type {
    return saturn_especial_decls_types[
        @intFromEnum(decl)
    ];
}
