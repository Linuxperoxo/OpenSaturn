// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modsys.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const decls: type = @import("root").decls;
const modules: type = @import("root").modules;
const config: type = @import("root").config;
const interfaces: type = @import("root").interfaces;
const kernel: type = @import("root").kernel;

const saturn_modules = r: {
    const aux: type = opaque {
        pub fn check_module_arch(mod: *const interfaces.module.ModuleDescription_T) anyerror!void {
            for(mod.arch) |mod_arch| {
                if(config.arch.options.Target == mod_arch) return;
            }
            if(!config.modules.options.IgnoreModuleWithArchNotSupported) {
                @compileError("module name " ++
                    mod.name ++
                    " is not supported by target architecture " ++
                    @tagName(config.arch.options.Target)
                );
            }
            return error.IgnoreThis;
        }

        pub fn check_module_in_menuconfig(mod: *const interfaces.module.ModuleDescription_T) void {
            if(!@hasField(config.modules.menuconfig.Menuconfig_T, mod.name))  @compileError(
                "module " ++
                mod.name ++
                " needs to be added in Menuconfig_T"
            );
        }

        pub fn check_module_load(mod: *const interfaces.module.ModuleDescription_T) anyerror!void {
            return if(mod.load == .unlinkable) return error.IgnoreThis else {};
        }
    };
    // logica de verificacao:
    var modules_check_index: usize = 0;
    var modules_check = [_]?interfaces.module.ModuleDescription_T {
        null
    } ** modules.__SaturnAllMods__.len;
    for(modules.__SaturnAllMods__) |mod| {
        if(!decls.container_decl_exist(mod, .module)) {
            @compileError(
                decls.what_is_decl(.module) ++
                " is not defined in the module file " ++
                @typeName(mod)
            );
        }
        if(!decls.container_decl_type(@TypeOf(mod.__SaturnModuleDescription__), .module)) {
            @compileError(
                "declaration " ++
                decls.what_is_decl(.module) ++
                " for module " ++
                @typeName(mod) ++
                " must be type: " ++
                @typeName(decls.what_is_decl_type(.module))
            );
        }
        aux.check_module_load(&mod.__SaturnModuleDescription__) catch continue;
        aux.check_module_in_menuconfig(&mod.__SaturnModuleDescription__);
        aux.check_module_arch(&mod.__SaturnModuleDescription__) catch continue;
        modules_check[modules_check_index] = mod.__SaturnModuleDescription__; modules_check_index += 1;
    }
    break :r t: {
        var satisfied_modules: [modules_check_index]interfaces.module.ModuleDescription_T = undefined;
        for(0..modules_check_index) |i| {
            satisfied_modules[i] = modules_check[i].?;
        }
        break :t satisfied_modules;
    };
};

// saturn_modules ja tem os modulos organizados, respeitando suas dependencias
// de inicializacao. Essa resolucao deve sempre ser resolvida em comptime
const saturn_modules_resolved = r: {
    // e aqui onde resolvemos as dependencias dos modulos
    const aux: type = opaque {
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

        fn count_comptime_mods_with_handler(comptime handler: *const fn(comptime *const interfaces.module.ModuleDescription_T) bool) usize {
            return t: {
                var count: usize = 0;
                for(0..saturn_modules.len) |i| {
                    count += if(saturn_modules[i].load == .linkable and handler(&saturn_modules[i])) 1 else 0;
                }
                break :t count;
            };
        }

        pub fn comptime_mods_of_type(
            comptime mod_type: enum { with_deps, with_out_deps}
        ) ?[if(mod_type == .with_deps) with_deps else with_out_deps]interfaces.module.ModuleDescription_T {
            if((mod_type == .with_deps and with_deps == 0)
                or (mod_type == .with_deps and with_deps == 0)) return null;
            var mods: [if(mod_type == .with_deps) with_deps else with_out_deps]interfaces.module.ModuleDescription_T = undefined;
            var mods_index: usize = 0;
            for(saturn_modules) |mod| {
                if(if(mod_type == .with_deps) (mod.deps != null) else (mod.deps == null)) {
                    mods[mods_index] = mod; mods_index += 1;
                }
            }
            return mods;
        }

        pub fn map_of_resolved_deps(
            comptime mods: *const [with_out_deps]interfaces.module.ModuleDescription_T,
            comptime mod: *const interfaces.module.ModuleDescription_T
        ) [mod.deps.?.len]u1 {
            var map =  [_]u1 {
                0
            } ** mod.deps.?.len;
            for(mod.deps.?, 0..) |dep, i| {
                for(mods) |m| {
                    if(kernel.utils.mem.eql(dep, m.name, .{
                        .len = true,
                        .case = false, // nao consideramos cases
                    })) map[i] = 1;
                }
            }
            return map;
        }
    };
    const mods_with_out_deps = aux.comptime_mods_of_type(.with_out_deps);
    var mods_with_deps = aux.comptime_mods_of_type(.with_deps);
    _ = &mods_with_deps;
    if(mods_with_deps == null) break :r mods_with_out_deps; // sem resolucao de dependencia
    for(mods_with_deps.?) |mod| {
        const deps_map = aux.map_of_resolved_deps(&mods_with_out_deps.?, &mod);
        for(deps_map) |@"?"| {
            if(@"?" == 1) continue;
        }
    }
    break :r mods_with_out_deps.? ++ mods_with_deps.?;
};

pub fn saturn_modules_loader() void {
    inline for(saturn_modules_resolved) |module| {
        // Skip nao pode ser comptime se nao vamos ter um
        // erro de compilacao, ja que ele vai tentar carregar
        // os modulos em comptime
        skip: {
            switch(comptime module.load) {
                .dinamic => {},
                .unlinkable => {},
                .linkable => {
                    // comptime apenas para deixar explicito
                    comptime {
                        if(config.modules.options.UseMenuconfigAsRef) {
                            switch(@field(config.modules.menuconfig.ModulesSelection, module.name)) {
                                .yes => {},
                                .no => break :skip,
                            }
                        }
                    }
                    @call(.never_inline, module.init, .{}) catch {
                        // klog error
                    };
                },
            }
            // resolvendo modulo com base no seu tipo
            switch(comptime module.type) {
                .driver => {},
                .syscall => {},
                .interrupt => {},
                .irq => {},
                .filesystem => {
                    switch(comptime module.type.filesystem) {
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
