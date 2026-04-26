// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: extern.zig     │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const types: type = @import("types.zig");

const Mod_T: type = types.Mod_T;
const ModErr_T: type = types.ModErr_T;
const Mods_T: type = types.Mods_T;
const ModInfo_T: type = types.ModInfo_T;
const ModControlFlags_T: type = types.ModControlFlags_T;

const kernel_modules: *Mods_T = &@import("kernel_modules.zig").kernel_modules;

/// * init module
pub noinline fn initmod(module_name: []const u8) ModErr_T!void {
    const module_info: *ModInfo_T = kernel_modules.search(module_name) catch return ModErr_T.NoNFound;

    if(module_info.module.deps != null) {
        for(module_info.module.deps.?) |dep| {
            if(kernel_modules.search(dep)) |dep_info| {
                if(!dep_info.running)
                    return ModErr_T.ObsoleteDependency;
            } else |_| {
                return ModErr_T.ObsoleteDependency;
            }
        }
    }

    if(module_info.flags.anon == 1 or
        module_info.flags.init == 0) return ModErr_T.OperationDenied;
    if(!module_info.running) {
        module_info.module.init() catch return ModErr_T.InitFailed;
        module_info.running = true;
    }
}

/// * kill module
pub noinline fn killmod(module_name: []const u8) ModErr_T!void {
    const module_info: *ModInfo_T = kernel_modules.search(module_name) catch return ModErr_T.NoNFound;
    if(module_info.flags.anon == 1 or
        module_info.flags.exit == 0) return ModErr_T.OperationDenied;
    if(module_info.running) {
        module_info.module.exit() catch return ModErr_T.ExitFailed;
        module_info.running = false;
    }
}

/// * schmod module
pub noinline fn schmod(module_name: []const u8) ModErr_T!*ModInfo_T {
    const module_info: *ModInfo_T  = kernel_modules.search(module_name) catch return ModErr_T.NoNFound;
    if(module_info.flags.anon == 1) return ModErr_T.OperationDenied;
    return module_info;
}
