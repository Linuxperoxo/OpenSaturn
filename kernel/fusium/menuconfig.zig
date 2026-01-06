// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: menuconfig.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const arch: type = @import("root").code.arch;
const config: type = @import("root").config;

const FusionerSelection = r: {
    if(!config.fusium.options.ForceFusiumArchOverrider) break :r config.fusium.menuconfig.FusiumSelection;
    if(arch.__SaturnArchDescription__.overrider.fusioners == null) {
        if(config.fusium.options.IgnoreFusiumArchIsEmpty) break :r config.fusium.menuconfig.FusiumSelection;
        @compileError(
            "fusium: ForceModuleArchOverrider = true expects an architecture fusioners overrider, but the " ++
            @tagName(config.arch.options.Target)
            ++ " architecture does not have an fusioners overrider"
        );
    }
    var overrider_menuconfig = if(arch.__SaturnArchDescription__.overrider.fusioners.?.default == null) config.fusium.menuconfig.FusiumSelection else t: {
        var menuconfig_with_default: config.fusium.menuconfig.Menuconfig_T = undefined;
        for(@typeInfo(@TypeOf(menuconfig_with_default)).@"struct".fields) |field| {
            @field(menuconfig_with_default, field.name) =
                arch.__SaturnArchDescription__.overrider.fusioners.?.default.?;
        }
        break :t menuconfig_with_default;
    };
    for(arch.__SaturnArchDescription__.overrider.fusioners.?.overriders) |overrider| {
        if(!@hasField(config.fusium.menuconfig.Menuconfig_T, overrider.fusioner)) {
            if(!config.fusium.options.IgnoreNoExistentFusiumInOverrider) @compileError(
                "fusium: attempt to overrider a non-existent fusioner " ++
                overrider.fusioner ++
                " in arch " ++
                @tagName(config.arch.options.Target)
            );
            continue;
        }
        @field(overrider_menuconfig, overrider.fusioner) = overrider.value;
    }
    break :r overrider_menuconfig;
};

pub fn fusioner_menuconf_value(comptime f_name: []const u8) anyerror!config.fusium.menuconfig.Load_T {
    return if(!@hasField(config.fusium.menuconfig.Menuconfig_T, f_name)) error.NoNExists else
        @field(FusionerSelection, f_name);
}
