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

pub fn find_module_by_name(mod_name: []const u8) anyerror!*const module.ModuleDescription_T {
    for(&lmodules.saturn_modules) |*mod_desc| {
        if(mem.eql(mod_desc.mod.name, mod_name, .{ .case = true}))
            return mod_desc;
    }
    return error.NoNFound;
}

pub fn find_module_lib_by_name(mod: *const module.ModuleDescription_T, lib_name: []const u8) anyerror!module.ModuleDescriptionLibMine_T {
    if(mod.libs.mines == null) return error.NoNFound;
    for(mod.libs.mines.?) |mine_lib| {
        if(mem.eql(lib_name, mine_lib.name, .{ .case = true }))
            return mine_lib;
    }
    return error.NoNFound;
}

pub fn mod_whitelisted(mod_name: []const u8, lib: module.ModuleDescriptionLibMine_T) bool {
    if(lib.flags.whitelist == 0) return true;
    if(lib.whitelist == null) return false;
    for(lib.whitelist.?) |whitelisted| {
        if(mem.eql(mod_name, whitelisted, .{ .case = true }))
            return true;
    }
    return false;
}

pub fn find_lib_version(mod_out: module.ModuleDescriptionLibOut_T, mod_mine: module.ModuleDescriptionLibMine_T) ?module.ModuleDescriptionLibMine_T.Version_T {
    const version: module.ModuleDescriptionLibMine_T.Version_T = r: switch(mod_out.version) {
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

pub fn valid_type_for_lib(mod: *const module.ModuleDescription_T, mod_mine: module.ModuleDescriptionLibMine_T) bool {
    if(mod_mine.m_types == null or mod_mine.m_types.?.len == 0) return true;
    for(mod_mine.m_types.?) |m_type| {
        if(m_type == mod.mod.type) return true;
    }
    return false;
}

// ============= for modules.zig

pub fn check_blacklist(mod: *const interfaces.module.ModuleDescription_T) void {
    if(mod.blacklist == null or mod.blacklist.?.len == 0) return;
    for(mod.blacklist.?) |blacklist_mod| {
        if(!@hasField(config.modules.menuconfig.Menuconfig_T, blacklist_mod))
            @compileError(
                "Modsys Error: module \"" ++ blacklist_mod ++ "\" in blacklist of module \"" ++
                mod.mod.name ++ "\" needs to be added in Menuconfig_T"
            );
        if(@field(menuconfig.ModulesSelection, blacklist_mod) == .yes)
            @compileError(
                "Modsys Error: module \"" ++ mod.mod.name ++
                "\" requires blacklist mod \"" ++ blacklist_mod ++
                "\" == .no, but found .yes. Check menuconfig and arch overrides."
            );
    }
}

pub fn check_module_arch(mod: *const interfaces.module.ModuleDescription_T) anyerror!void {
    for(mod.arch) |mod_arch| {
        if(config.arch.options.Target == mod_arch) return;
    }
    if(!config.modules.options.IgnoreModuleWithArchNotSupported) {
        @compileError(
            "Modsys Error: module name " ++ mod.mode.name ++
            " is not supported by target architecture " ++
            @tagName(config.arch.options.Target)
        );
    }
    return error.IgnoreThis;
}

pub fn check_module_in_menuconfig(mod: *const interfaces.module.ModuleDescription_T) void {
    if(!@hasField(config.modules.menuconfig.Menuconfig_T, mod.mod.name)) @compileError(
        "Modsys Error: module \"" ++ mod.mod.name ++ "\" needs to be added in Menuconfig_T"
    );
}

pub fn check_module_load(mod: *const interfaces.module.ModuleDescription_T) anyerror!void {
    return if(mod.load == .unlinkable) return error.IgnoreThis else {};
}

pub fn check_module_menuconfig_enable(mod: *const interfaces.module.ModuleDescription_T) anyerror!void {
    if(config.modules.options.UseMenuconfigAsRef) {
        switch(@field(menuconfig.ModulesSelection, mod.mod.name)) {
            .yes => {},
            .no => return error.IgnoreThis,
        }
    }
}

pub fn check_module_collision() usize {
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
                if(!config.modules.options.IgnoreModuleCollision) {
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
