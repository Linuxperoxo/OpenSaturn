// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const menuconfig: type = @import("menuconfig.zig");
const config: type = @import("root").config;
const module: type = @import("root").interfaces.module;
const mem: type = @import("root").lib.kernel.mem;
const lmodules: type = @import("modules.zig"); // local modules
const gmodules: type = @import("root").modules; // global modules

// =============== for smll.zig

pub fn findModuleByName(mod_name: []const u8) anyerror!*const module.ModuleDescription {
    for(&lmodules.saturn_modules) |*mod_desc| {
        if(mem.eql(mod_desc.mod.name, mod_name, .{ .case = true}))
            return mod_desc;
    }
    return error.NoNFound;
}

pub fn findModuleLibByName(mod: *const module.ModuleDescription, lib_name: []const u8) anyerror!module.ModuleDescriptionLibMine {
    if(mod.libs.mines == null) return error.NoNFound;
    for(mod.libs.mines.?) |mine_lib| {
        if(mem.eql(lib_name, mine_lib.name, .{ .case = true }))
            return mine_lib;
    }
    return error.NoNFound;
}

pub fn modWhitelisted(mod_name: []const u8, lib: module.ModuleDescriptionLibMine) bool {
    if(lib.flags.whitelist == 0) return true;
    if(lib.whitelist == null) return false;
    for(lib.whitelist.?) |whitelisted| {
        if(mem.eql(mod_name, whitelisted, .{ .case = true }))
            return true;
    }
    return false;
}

pub fn findLibVersion(mod_out: module.ModuleDescriptionLibOut, mod_mine: module.ModuleDescriptionLibMine) ?module.ModuleDescriptionLibMine.Version {
    const version: module.ModuleDescriptionLibMine.Version = r: switch(mod_out.version) {
        .stable => break :r mod_mine.versions[mod_mine.stable],
        .current => break :r mod_mine.versions[mod_mine.current],
        .tag => |tag| {
            for(mod_mine.versions) |version| {
                if(mem.eql(version.tag, tag, .{ .case = false }))
                    break :r version;
            }
            return null;
        },
    };
    return version;
}

pub fn validTypeForLib(mod: *const module.ModuleDescription, mod_mine: module.ModuleDescriptionLibMine) bool {
    if(mod_mine.m_types == null or mod_mine.m_types.?.len == 0) return true;
    for(mod_mine.m_types.?) |m_type| {
        if(m_type == mod.mod.type) return true;
    }
    return false;
}

// ============= for modules.zig

pub fn checkBlacklist(mod: *const interfaces.module.ModuleDescription) void {
    if(mod.blacklist == null or mod.blacklist.?.len == 0) return;
    for(mod.blacklist.?) |blacklist_mod| {
        if(!@hasField(config.modules.menuconfig.Menuconfig, blacklist_mod))
            @compileError(
                "Modsys Error: module \"" ++ blacklist_mod ++ "\" in blacklist of module \"" ++
                mod.mod.name ++ "\" needs to be added in Menuconfig"
            );
        if(@field(menuconfig.modules_selection, blacklist_mod) == .yes)
            @compileError(
                "Modsys Error: module \"" ++ mod.mod.name ++
                "\" requires blacklist mod \"" ++ blacklist_mod ++
                "\" == .no, but found .yes. Check menuconfig and arch overrides."
            );
    }
}

pub fn checkModuleArch(mod: *const interfaces.module.ModuleDescription) anyerror!void {
    for(mod.arch) |mod_arch| {
        if(config.arch.options.target == mod_arch) return;
    }
    if(!config.modules.options.ignore_module_with_arch_not_supported) {
        @compileError(
            "Modsys Error: module name " ++ mod.mode.name ++
            " is not supported by target architecture " ++
            @tagName(config.arch.options.target)
        );
    }
    return error.IgnoreThis;
}

pub fn checkModuleInMenuconfig(mod: *const interfaces.module.ModuleDescription) void {
    if(!@hasField(config.modules.menuconfig.Menuconfig, mod.mod.name)) @compileError(
        "Modsys Error: module \"" ++ mod.mod.name ++ "\" needs to be added in Menuconfig"
    );
}

pub fn checkModuleLoad(mod: *const interfaces.module.ModuleDescription) anyerror!void {
    return if(mod.load == .unlinkable) return error.IgnoreThis else {};
}

pub fn checkModuleMenuconfigEnable(mod: *const interfaces.module.ModuleDescription) anyerror!void {
    if(config.modules.options.use_menuconfig_as_ref) {
        switch(@field(menuconfig.modules_selection, mod.mod.name)) {
            .yes => {},
            .no => return error.IgnoreThis,
        }
    }
}

pub fn checkModuleCollision() usize {
    var collision_count: usize = 0;
    for(gmodules.__SaturnAllMods__, 0..) |mod, i| {
        for(0..i) |j| {
            if(mem.eql(
                mod.__SaturnModuleDescription__.mod.name, gmodules.__SaturnAllMods__[j].__SaturnModuleDescription__.mod.name, .{
                    .len = true,
                    .case = false
                }
            )) {
                // caso modulos diferentes compartilham do mesmo nome, precisa dar erro, isso e critico
                if(&mod.__SaturnModuleDescription__ != &gmodules.__SaturnAllMods__[j].__SaturnModuleDescription__) {
                    @compileError(
                        "Modsys Error: collision module name " ++ gmodules.__SaturnAllMods__[j].__SaturnModuleDescription__.mod.name ++
                        " files " ++ @typeName(gmodules.__SaturnAllMods__[j]) ++
                        " " ++ @typeName(mod)
                    );
                }
                if(!config.modules.options.ignore_module_collision) {
                    @compileError(
                        "Modsys Error: collision with the module " ++ mod.__SaturnModuleDescription__.mod.name ++
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
