// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").interfaces.module;
const mem: type = @import("root").lib.utils.mem;
const modsys: type = @import("modsys.zig");

pub fn find_module_by_name(mod_name: []const u8) anyerror!*const module.ModuleDescription_T {
    for(&modsys.saturn_modules) |*mod_desc| {
        if(mem.eql(mod_desc.name, mod_name, .{ .case = true}))
            return mod_desc;
    }
    return error.NoNFound;
}

pub fn find_module_lib_by_name(mod: *const module.ModuleDescription_T, lib_name: []const u8) anyerror!module.ModuleDescriptionLibMine_T {
    if(mod.libs.mines == null
        or mod.libs.outside.?.len == 0) return error.NoNFound;
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
        if(m_type == mod.type) return true;
    }
    return false;
}
