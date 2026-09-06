// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: menuconfig.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const arch: type = @import("root").__SaturnArchImpl__.arch;
const config: type = @import("root").config;

pub const modules_selection: config.modules.menuconfig.Menuconfig = r: {
    if(!config.modules.options.force_module_arch_overrider) break :r config.modules.menuconfig.modules_selection;
    if(arch.__SaturnArchDescription__.overrider.modules == null
        or arch.__SaturnArchDescription__.overrider.modules.?.len == 0) {
        if(!config.modules.options.ignore_overrider_if_no_exist) @compileError(
            "Modsys Error: ForceModuleArchOverrider = true expects an architecture module overrider, but the " ++
            @tagName(config.arch.options.target)
            ++ " architecture does not have an module overrider"
        );
        break :r config.modules.menuconfig.modules_selection;
    }
    var over_menuconfig = config.modules.menuconfig.modules_selection;
    for(arch.__SaturnArchDescription__.overrider.modules.?) |overrider| {
        if(!@hasField(config.modules.menuconfig.Menuconfig, overrider.module)) @compileError(
            "Modsys Error: attempt to overrider a non-existent module " ++
            overrider.module ++
            " in arch " ++
            @tagName(config.arch.options.target)
        );
        @field(over_menuconfig, overrider.module) = overrider.value;
    }
    break :r over_menuconfig;
};
