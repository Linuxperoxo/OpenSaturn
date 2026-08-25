// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: extern.zig     │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const types: type = @import("types.zig");

const Mod: type = types.Mod;
const ModErr: type = types.ModErr;
const Mods: type = types.Mods;
const ModInfo: type = types.ModInfo;
const ModControlFlags: type = types.ModControlFlags;

const kernel_modules: *Mods = &@import("kernel_modules.zig").kernel_modules;

/// * init module
pub noinline fn initmod(module_name: []const u8) ModErr!void {
    const module_info: *ModInfo = kernel_modules.search(module_name) catch return ModErr.NoNFound;

    if(module_info.module.deps != null) {
        for(module_info.module.deps.?) |dep| {
            if(kernel_modules.search(dep)) |dep_info| {
                if(!dep_info.running)
                    return ModErr.ObsoleteDependency;
            } else |_| {
                return ModErr.ObsoleteDependency;
            }
        }
    }

    if(module_info.flags.anon == 1 or
        module_info.flags.init == 0) return ModErr.OperationDenied;
    if(!module_info.running) {
        module_info.module.init() catch return ModErr.InitFailed;
        module_info.running = true;
    }
}

/// * kill module
pub noinline fn killmod(module_name: []const u8) ModErr!void {
    const module_info: *ModInfo = kernel_modules.search(module_name) catch return ModErr.NoNFound;
    if(module_info.flags.anon == 1 or
        module_info.flags.exit == 0) return ModErr.OperationDenied;
    if(module_info.running) {
        module_info.module.exit() catch return ModErr.ExitFailed;
        module_info.running = false;
    }
}

/// * schmod module
pub noinline fn schmod(module_name: []const u8) ModErr!*ModInfo {
    const module_info: *ModInfo  = kernel_modules.search(module_name) catch return ModErr.NoNFound;
    if(module_info.flags.anon == 1) return ModErr.OperationDenied;
    return module_info;
}
