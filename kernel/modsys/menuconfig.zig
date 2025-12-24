// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: menuconfig.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("root").config;

pub const ModulesSelection: config.modules.menuconfig.Menuconfig_T = r: {
    if(!config.modules.options.ForceModuleArchOverrider) break :r config.modules.menuconfig.ModulesSelection;
    if(arch.__SaturnArchDescription__.overrider.modules == null
        or arch.__SaturnArchDescription__.overrider.modules.?.len == 0) {
        if(!config.modules.options.IgnoreOverriderIfNoExist) @compileError(
            "modsys: ForceModuleArchOverrider = true expects an architecture module overrider, but the " ++
            @tagName(config.arch.options.Target)
            ++ " architecture does not have an module overrider"
        );
        break :r config.modules.menuconfig.ModulesSelection;
    }
    var over_menuconfig = config.modules.menuconfig.ModulesSelection;
    for(arch.__SaturnArchDescription__.overrider.modules.?) |overrider| {
        if(!@hasField(config.modules.menuconfig.Menuconfig_T, overrider.module)) @compileError(
            "modsys: attempt to overrider a non-existent module " ++
            overrider.module ++
            " in arch " ++
            @tagName(config.arch.options.Target)
        );
        @field(over_menuconfig, overrider.module) = overrider.value;
    }
    break :r over_menuconfig;
};
