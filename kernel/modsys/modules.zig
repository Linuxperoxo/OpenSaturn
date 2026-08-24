// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: modules.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const decls: type = @import("root").decls;
const modules: type = @import("root").modules;
const mem: type = @import("root").lib.kernel.mem;
const interfaces: type = @import("root").interfaces;
const aux: type = @import("aux.zig");

pub const saturn_modules = r: {
    var modules_check_index: usize = 0;
    var modules_check: [(modules.__SaturnAllMods__.len - aux.check_module_collision())]interfaces.module.ModuleDescription = undefined;
    for(modules.__SaturnAllMods__, 0..) |mod, i| {
        t: {
            for(0..i) |j| {
                if(mem.eql(
                    mod.__SaturnModuleDescription__.mod.name, modules.__SaturnAllMods__[j].__SaturnModuleDescription__.mod.name, .{
                        .len = true,
                        .case = false,
                    }
                )) break :t {};
            }

            if(!decls.container_decl_exist(mod, .module)) {
                @compileError(
                    "Modsys Error: " ++ decls.what_is_decl(.module) ++
                    " is not defined in the module file " ++ @typeName(mod)
                );
            }

            if(!decls.container_decl_type(@TypeOf(mod.__SaturnModuleDescription__), .module)) {
                @compileError(
                    "Modsys Error: declaration " ++ decls.what_is_decl(.module) ++
                    " for module " ++ @typeName(mod) ++
                    " must be type: " ++ @typeName(decls.what_is_decl_type(.module))
                );
            }

            aux.check_module_load(&mod.__SaturnModuleDescription__) catch continue;
            aux.check_module_in_menuconfig(&mod.__SaturnModuleDescription__);
            aux.check_blacklist(&mod.__SaturnModuleDescription__);
            aux.check_module_menuconfig_enable(&mod.__SaturnModuleDescription__) catch continue;
            aux.check_module_arch(&mod.__SaturnModuleDescription__) catch continue;

            modules_check[modules_check_index] = mod.__SaturnModuleDescription__;
            modules_check_index += 1;
        }
    }
    break :r @as(
        *const [modules_check_index]interfaces.module.ModuleDescription, @ptrCast(&modules_check)
    ).*;
};
