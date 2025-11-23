// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modsys.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const decls: type = @import("root").decls;
const modules: type = @import("root").modules;
const config: type = @import("root").config;
const interfaces: type = @import("root").interfaces;
const kernel: type = @import("root").kernel;

// saturn_modules ja tem os modulos organizados, respeitando suas dependencias
// de inicializacao. Essa resolucao deve sempre ser resolvida em comptime
const saturn_modules = r: {
    // e aqui onde resolvemos as dependencias dos modulos
    const aux: type = opaque {
        pub fn check_mod_exists(comptime name: []const u8) bool {
            return (@hasField(config.modules.menuconfig.Menuconfig_T, name)
                and @field(config.modules.menuconfig.ModulesSelection, name) == .yes);
        }

        fn count_comptime_mods_with_handler(comptime handler: *const fn(*const interfaces.module.ModuleDescription_T) bool) usize {
            return t: {
                var count: usize = 0;
                for(modules.__SaturnAllMods__) |mod| {
                    count += if(mod.__SaturnModuleDescription__.load == .linkable
                        and check_mod_exists(mod.name)
                        and handler(&mod.__SaturnModuleDescription__)) 1 else 0;
                }
                break :t count;
            };
        }

        const with_deps = count_comptime_mods_with_handler(
            &opaque {
                pub fn @"with_deps?"(comptime mod: *const interfaces.module.ModuleDescription_T) bool {
                    return (mod.deps != null);
                }
            }.@"with_deps?"
        );
        const with_out_deps = count_comptime_mods_with_handler(
            &opaque {
                pub fn @"with_out_deps?"(comptime mod: *const interfaces.module.ModuleDescription_T) bool {
                    return (mod.deps == null);
                }
            }.@"with_out_deps?"
        );

        pub fn comptime_mods_of_type(
            comptime mod_type: enum { with_deps, with_out_deps}
        ) ?[if(mod_type == .with_deps) with_deps else with_out_deps]interfaces.module.ModuleDescription_T {
            if((mod_type == .with_deps and with_deps == 0)
                or (mod_type == .with_deps and with_deps == 0)) return null;
            const handler: type = opaque {
                var mods: [if(mod_type == .with_deps) with_deps else with_out_deps]interfaces.module.ModuleDescription_T = undefined;
                var mods_index: usize = 0;

                pub fn check(mod: *const interfaces.module.ModuleDescription_T) bool {
                    if(if(mod_type == .with_deps) (mod.deps != null) else (mod.deps == null)) {
                        mods[mods_index] = mod.*; mods_index += 1;
                    }
                    return true;
                }
            };
            _ = count_comptime_mods_with_handler(&handler.check); return handler.mods;
        }

        pub fn map_of_resolved_deps(comptime mods: *[with_out_deps]interfaces.module.ModuleDescription_T, comptime mod: *interfaces.module.ModuleDescription_T) [mod.deps.?.len]u1 {
            var map =  [_]u1 {
                0
            } ** mod.deps.?.len;
            for(mod.deps.?, 0..) |dep, i| {
                for(mods) |m| {
                    if(kernel.mem.eql(dep, m.name, .{
                        .len = true,
                        .case = false, // nao consideramos cases
                    })) map[i] = 1;
                }
            }
            return map;
        }
    };
    const mods_with_out_deps = aux.comptime_mods_of_type(.with_out_deps);
    const mods_with_deps = aux.comptime_mods_of_type(.with_deps);
    if(mods_with_deps == null) break :r mods_with_out_deps; // sem resolucao de dependencia
    for(mods_with_deps) |mod| {
        var deps_map = aux.map_of_resolved_deps(&mods_with_out_deps, &mod);
        for(deps_map) |@"?"| {
            if(@"?" == 1) continue;
        }
    }
};

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
