// ┌───────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux_exposed.zig   │
// │            Author: Linuxperoxo                    │
// └───────────────────────────────────────────────────┘

const modsys: type = @import("modsys.zig");
const module: type = @import("root").interfaces.module;
const mem: type = @import("root").kernel.utils.compile.mem;
const config: type = @import("root").config;

pub fn find_module_by_name(mod_name: []const u8) anyerror!*const module.ModuleDescription_T {
    for(&modsys.saturn_modules) |*smod| {
        if(mem.eql(mod_name, smod.name, .{ .case = true })) {
            return smod;
        }
    }
    return error.NoNFound;
}

pub fn mod_in_lib_whitelist(mod_name: []const u8, lib: module.ModuleDescriptionLibMine_T) bool {
    if(lib.flags.whitelist == 0) return true;
    if(lib.whitelist == null) return false;
    for(lib.whitelist.?) |white_mod| {
        if(mem.eql(mod_name, white_mod, .{ .case = true }))
            return true;
    }
    return false;
}

pub fn find_module_lib(mod: *const module.ModuleDescription_T, lib_name: []const u8) anyerror!module.ModuleDescriptionLibMine_T {
    if(mod.libs.mines == null) return error.NoNFound;
    for(mod.libs.mines.?) |mlib| {
        if(mem.eql(lib_name, mlib.name, .{ .case = false })) {
            return mlib;
        }
    }
    return error.NoNFound;
}
