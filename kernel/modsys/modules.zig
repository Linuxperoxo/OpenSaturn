// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: modules.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const decls: type = @import("root").decls;
const modules: type = @import("root").modules;
const lib: type = @import("root").lib;
const config: type = @import("root").config;
const interfaces: type = @import("root").interfaces;
const menuconfig: type = @import("menuconfig.zig");

pub const saturn_modules = r: {
    const aux: type = opaque {
        pub fn check_module_arch(mod: *const interfaces.module.ModuleDescription_T) anyerror!void {
            for(mod.arch) |mod_arch| {
                if(config.arch.options.Target == mod_arch) return;
            }
            if(!config.modules.options.IgnoreModuleWithArchNotSupported) {
                @compileError("module name " ++ mod.mode.name ++
                    " is not supported by target architecture " ++
                    @tagName(config.arch.options.Target)
                );
            }
            return error.IgnoreThis;
        }

        pub fn check_module_in_menuconfig(mod: *const interfaces.module.ModuleDescription_T) void {
            if(!@hasField(config.modules.menuconfig.Menuconfig_T, mod.mod.name)) @compileError(
                "module \"" ++ mod.mod.name ++ "\" needs to be added in Menuconfig_T"
            );
        }

        pub fn check_module_load(mod: *const interfaces.module.ModuleDescription_T) anyerror!void {
            return if(mod.load == .unlinkable) return error.IgnoreThis else {};
        }

        pub fn check_module_menuconfig_enable(mod: *const interfaces.module.ModuleDescription_T) anyerror!void {
            if(config.modules.options.UseMenuconfigAsRef) {
                switch(@field(menuconfig.ModulesSelection, mod.mod.name)) {
                    .yes => {},
                    .no => return error.IgnoreThis,
                }
            }
        }

        pub fn check_module_collision() usize {
            var collision_count: usize = 0;
            for(modules.__SaturnAllMods__, 0..) |mod, i| {
                for(0..i) |j| {
                    if(lib.utils.mem.eql(
                        mod.__SaturnModuleDescription__.mod.name, modules.__SaturnAllMods__[j].__SaturnModuleDescription__.mod.name, .{
                            .len = true,
                            .case = false
                        }
                    )) {
                        // caso modulos diferentes compartilham do mesmo nome, precisa dar erro, isso e critico
                        if(&mod.__SaturnModuleDescription__ != &modules.__SaturnAllMods__[j].__SaturnModuleDescription__) {
                            @compileError(
                                "modsys: collision module name " ++ modules.__SaturnAllMods__[j].__SaturnModuleDescription__.mod.name ++
                                " files " ++ @typeName(modules.__SaturnAllMods__[j]) ++
                                " " ++ @typeName(mod)
                            );
                        }
                        if(!config.modules.options.IgnoreModuleCollision) {
                            @compileError(
                                "modsys: collision with the module " ++ mod.__SaturnModuleDescription__.mod.name ++
                                " itself (double module register)"
                            );
                        }
                        collision_count += 1;
                        break;
                    }
                }
            }
            return collision_count;
        }
    };
    var modules_check_index: usize = 0;
    var modules_check: [(modules.__SaturnAllMods__.len - aux.check_module_collision())]interfaces.module.ModuleDescription_T = undefined;
    for(modules.__SaturnAllMods__, 0..) |mod, i| {
        t: {
            for(0..i) |j| {
                if(lib.utils.mem.eql(
                    mod.__SaturnModuleDescription__.mod.name, modules.__SaturnAllMods__[j].__SaturnModuleDescription__.mod.name, .{
                        .len = true,
                        .case = false,
                    }
                )) break :t {};
            }
            if(!decls.container_decl_exist(mod, .module)) {
                @compileError(
                    decls.what_is_decl(.module) ++
                    " is not defined in the module file " ++ @typeName(mod)
                );
            }
            if(!decls.container_decl_type(@TypeOf(mod.__SaturnModuleDescription__), .module)) {
                @compileError(
                    "declaration " ++ decls.what_is_decl(.module) ++
                    " for module " ++ @typeName(mod) ++
                    " must be type: " ++ @typeName(decls.what_is_decl_type(.module))
                );
            }
            aux.check_module_load(&mod.__SaturnModuleDescription__) catch continue;
            aux.check_module_in_menuconfig(&mod.__SaturnModuleDescription__);
            aux.check_module_menuconfig_enable(&mod.__SaturnModuleDescription__) catch continue;
            aux.check_module_arch(&mod.__SaturnModuleDescription__) catch continue;
            modules_check[modules_check_index] = mod.__SaturnModuleDescription__;
            modules_check_index += 1;
        }
    }
    break :r @as(
        *const [modules_check_index]interfaces.module.ModuleDescription_T, @ptrCast(&modules_check)
    ).*;
};
