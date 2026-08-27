// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: menuconfig.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const arch: type = @import("root").__SaturnArchImpl__.arch;
const config: type = @import("root").config;

const fusioner_selection = r: {
    if(!config.fusium.options.force_fusium_arch_overrider) break :r config.fusium.menuconfig.fusium_selection;
    if(arch.__SaturnArchDescription__.overrider.fusioners == null) {
        if(config.fusium.options.ignore_fusium_arch_is_empty) break :r config.fusium.menuconfig.fusium_selection;
        @compileError(
            "fusium: ForceModuleArchOverrider = true expects an architecture fusioners overrider, but the " ++
            @tagName(config.arch.options.target)
            ++ " architecture does not have an fusioners overrider"
        );
    }
    var overrider_menuconfig = if(arch.__SaturnArchDescription__.overrider.fusioners.?.default == null) config.fusium.menuconfig.fusium_selection else t: {
        var menuconfig_with_default: config.fusium.menuconfig.Menuconfig = undefined;
        for(@typeInfo(@TypeOf(menuconfig_with_default)).@"struct".fields) |field| {
            @field(menuconfig_with_default, field.name) =
                arch.__SaturnArchDescription__.overrider.fusioners.?.default.?;
        }
        break :t menuconfig_with_default;
    };
    for(arch.__SaturnArchDescription__.overrider.fusioners.?.overriders) |overrider| {
        if(!@hasField(config.fusium.menuconfig.Menuconfig, overrider.fusioner)) {
            if(!config.fusium.options.ignore_no_existent_fusium_in_overrider) @compileError(
                "fusium: attempt to overrider a non-existent fusioner " ++
                overrider.fusioner ++
                " in arch " ++
                @tagName(config.arch.options.target)
            );
            continue;
        }
        @field(overrider_menuconfig, overrider.fusioner) = overrider.value;
    }
    break :r overrider_menuconfig;
};

pub fn fusionerMenuconfValue(comptime f_name: []const u8) anyerror!config.fusium.menuconfig.Load {
    return if(!@hasField(config.fusium.menuconfig.Menuconfig, f_name)) error.NoNExists else
        @field(fusioner_selection, f_name);
}
