// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: internal.zig    │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");

const Mod: type = types.Mod;
const Mods: type = types.Mods;
const ModType: type = types.ModType;
const ModErr: type = types.ModErr;
const ModInfo: type = types.ModInfo;
const ModControlFlags: type = types.ModControlFlags;

const kernel_modules: *Mods = &@import("kernel_modules.zig").kernel_modules;

/// * install module instance
pub noinline fn insmod(module: *const Mod, flags: ModControlFlags) ModErr!void {
    if(kernel_modules.search(module.name)) |_| {
        return ModErr.ModuleCollision;
    } else |err| {
        switch(err) {
            Mods.Err.KeyNotFound => {},
            else => return ModErr.OperationFailed,
        }
    }

    const module_info: *ModInfo = try ModInfo.create(
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
        catch return ModErr.OperationFailed;
}

/// * remove module instance
pub noinline fn rmmod(module: *const Mod) ModErr!void {
    const module_info = kernel_modules.search(module.name) catch return ModErr.NoNFound;

    if(module_info.running) {
        module_info.module.exit() catch return ModErr.OperationFailed;
        module_info.running = false;
    }

    kernel_modules.del(module_info.module.name, &allocator.sba.allocator)
        catch return ModErr.OperationFailed;

    try module_info.destroy();
}

/// * update flags of current module instance
pub noinline fn updmod(module: *const Mod, flags: ModControlFlags) ModErr!void {
    const module_info: *ModInfo = kernel_modules.search(module.name) catch return ModErr.NoNFound;
    module_info.flags = flags;
}

/// * check module deps
pub noinline fn depmod(module: *const Mod) bool {
    if(module.deps != null) {
        for(module.deps.?) |dep| {
            const dep_info: *ModInfo = kernel_modules.search(dep) catch return false;
            if(!dep_info.running)
                return false;
        }
    }
    return true;
}
