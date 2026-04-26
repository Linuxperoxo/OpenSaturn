// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: internal.zig    │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");

const Mod_T: type = types.Mod_T;
const Mods_T: type = types.Mods_T;
const ModType_T: type = types.ModType_T;
const ModErr_T: type = types.ModErr_T;
const ModInfo_T: type = types.ModInfo_T;
const ModControlFlags_T: type = types.ModControlFlags_T;

const kernel_modules: *Mods_T = &@import("kernel_modules.zig").kernel_modules;

/// * install module instance
pub noinline fn insmod(module: *const Mod_T, flags: ModControlFlags_T) ModErr_T!void {
    if(kernel_modules.search(module.name)) |_| {
        return ModErr_T.ModuleCollision;
    } else |err| {
        switch(err) {
            Mods_T.Err_T.KeyNotFound => {},
            else => return ModErr_T.OperationFailed,
        }
    }

    const module_info: *ModInfo_T = try ModInfo_T.create(
        module,
        r: {
            if(flags.init == 1 and module.depmod()) {
                module.init() catch break :r false;
                break :r true;
            }
            break :r false;
        },
    flags
    );

    kernel_modules.add(module_info.module.name, module_info, &allocator.sba.allocator)
        catch return ModErr_T.OperationFailed;
}

/// * remove module instance
pub noinline fn rmmod(module: *const Mod_T) ModErr_T!void {
    const module_info = kernel_modules.search(module.name) catch return ModErr_T.NoNFound;

    if(module_info.running) {
        module_info.module.exit() catch return ModErr_T.OperationFailed;
        module_info.running = false;
    }

    kernel_modules.del(module_info.module.name, &allocator.sba.allocator)
        catch return ModErr_T.OperationFailed;

    try module_info.destroy();
}

/// * update flags of current module instance
pub noinline fn updmod(module: *const Mod_T, flags: ModControlFlags_T) ModErr_T!void {
    const module_info: *ModInfo_T = kernel_modules.search(module.name) catch return ModErr_T.NoNFound;
    module_info.flags = flags;
}

/// * check module deps
pub noinline fn depmod(module: *const Mod_T) bool {
    if(module.deps != null) {
        for(module.deps.?) |dep| {
            const dep_info: *ModInfo_T = kernel_modules.search(dep) catch return false;
            if(!dep_info.running)
                return false;
        }
    }
    return true;
}
