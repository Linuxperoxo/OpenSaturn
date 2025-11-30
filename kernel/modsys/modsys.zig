// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modsys.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const decls: type = @import("root").decls;
const modules: type = @import("root").modules;
const config: type = @import("root").config;
const interfaces: type = @import("root").interfaces;
const kernel: type = @import("root").kernel;
const deps: type = @import("deps.zig");
const menuconfig: type = @import("menuconfig.zig");

pub const saturn_modules = r: {
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

        pub fn check_module_menuconfig_enable(mod: *const interfaces.module.ModuleDescription_T) anyerror!void {
            if(config.modules.options.UseMenuconfigAsRef) {
                switch(@field(menuconfig.ModulesSelection, mod.name)) {
                    .yes => {},
                    .no => return error.IgnoreThis,
                }
            }
        }
    };
    // logica de verificacao:
    var modules_check_index: usize = 0;
    var modules_check = [_]?interfaces.module.ModuleDescription_T {
        null
    } ** modules.__SaturnAllMods__.len;
    for(modules.__SaturnAllMods__, 0..) |mod, i| {
        for(0..i) |j| {
            // nao e o jeito mais eficiente de fazer isso, mas estamos no comptime, as
            // coisas precisam ser simples aqui
            if(kernel.utils.compile.mem.eql(
                modules.__SaturnAllMods__[j].__SaturnModuleDescription__.name,
                mod.__SaturnModuleDescription__.name,
                .{}
            )) @compileError(
                "modsys: collision module name " ++
                modules.__SaturnAllMods__[j].__SaturnModuleDescription__.name ++
                " files " ++
                @typeName(modules.__SaturnAllMods__[j]) ++
                " " ++
                @typeName(mod)
            );
        }
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
        aux.check_module_menuconfig_enable(&mod.__SaturnModuleDescription__) catch continue;
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

pub fn saturn_modules_loader() void {
    inline for(comptime deps.resolve_dependencies()) |module| {
        // Skip nao pode ser comptime se nao vamos ter um
        // erro de compilacao, ja que ele vai tentar carregar
        // os modulos em comptime
        skip: {
            switch(comptime module.load) {
                .dinamic => {},
                .unlinkable => {},
                .linkable => {
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
