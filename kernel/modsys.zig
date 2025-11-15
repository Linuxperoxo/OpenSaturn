// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modsys.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const decls: type = @import("root").decls;
const modules: type = @import("root").modules;
const config: type = @import("root").config;

pub fn saturn_modules_verify() void {
    for(modules.__SaturnAllMods__) |M| {
        const decl = decls.saturn_especial_decls[
            @intFromEnum(decls.DeclsOffset_T.module)
        ];
        if(!@hasDecl(M, decl)) {
            @compileError(
                decl ++ " is not defined in the module file " ++
                @typeName(M)
            );
        }
        const decl_type = @TypeOf(M.__SaturnModuleDescription__);
        const decl_expect_type = decls.saturn_especial_decls_types[
            @intFromEnum(decls.DeclsOffset_T.module)
        ];
        if(decl_type != decl_expect_type) {
            if(decl_type != decl_expect_type) {
                @compileError(
                    "declaration " ++ decl ++ " for module " ++
                    @typeName(M) ++
                    " must be type: " ++
                    @typeName(decls.saturn_especial_decls_types[
                        @intFromEnum(decls.DeclsOffset_T.module)
                    ])
                );
            }
        }
    }
}

pub fn saturn_modules_loader() void {
    inline for(modules.__SaturnAllMods__) |M| {
        // caso o modulo seja um modulo atualmente nao utilizavel, simplesmente damos skip
        if(M.__SaturnModuleDescription__.load == .unlinkable) continue;
        // Precisamos forçar um comptime aqui para evitar
        // erro de compilacao
        comptime arch: {
            for(M.__SaturnModuleDescription__.arch) |A| {
                if(config.arch.options.Target == A) {
                    break :arch;
                }
            }
            if(!config.modules.options.IgnoreModuleWithArchNotSupported) {
                @compileError("module file " ++
                    @typeName(M) ++
                    " is not supported by target architecture " ++
                    @tagName(config.arch.options.Target));
            }
            continue;
        }
        // Skip nao pode ser comptime se nao vamos ter um
        // erro de compilacao, ja que ele vai tentar carregar
        // os modulos em comptime
        skip: {
            switch(comptime M.__SaturnModuleDescription__.load) {
                .dinamic => {},
                .unlinkable => {},
                .linkable => {
                    // comptime apenas para deixar explicito
                    comptime {
                        if(config.modules.options.UseMenuconfigAsRef) {
                            if(!@hasField(config.modules.menuconfig.Menuconfig_T, M.__SaturnModuleDescription__.name)) {
                                @compileError(
                                    "module " ++
                                    M.__SaturnModuleDescription__.name ++
                                    " in file " ++
                                    @typeName(M) ++
                                    " needs to be added in Menuconfig_T"
                                );
                            }
                            switch(@field(config.modules.menuconfig.ModulesSelection, M.__SaturnModuleDescription__.name)) {
                                .yes => {},
                                .no => break :skip,
                            }
                        }
                    }
                    @call(.never_inline, M.__SaturnModuleDescription__.init, .{}) catch {
                        // klog error
                    };
                },
            }
            // resolvendo modulo com base no seu tipo
            switch(comptime M.__SaturnModuleDescription__.type) {
                .driver => {},
                .syscall => {},
                .interrupt => {},
                .irq => {},
                .filesystem => {
                    switch(comptime M.__SaturnModuleDescription__.type.filesystem) {
                        // caso o modulo fs use compile, vamos fazer uma
                        // montagem do fs em tempo de compilacao
                        .compile => {}, // call mount
                        .dinamic => break :skip,
                    }
                },
            }
        }
    }
}
