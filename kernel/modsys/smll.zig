// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: smll.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Saturn Static Module Library Linker

const module: type = @import("root").interfaces.module;
const config: type = @import("root").config;
const modsys: type = @import("modsys.zig");
const mem: type = @import("root").kernel.utils.mem;

pub fn search_all(comptime mod: *const module.ModuleDescription_T) [
    if(mod.libs.outside == null) 0 else
        mod.libs.outside.?.len
]?type {
    if(mod.libs.outside == null or mod.libs.outside.?.len == 0) @compileError(
        "modsys: " ++  mod.name ++ " request libs without outside lib"
    );
    var libs = [_]?type {
        null
    } ** mod.libs.outside.?.len;
    for(mod.libs.outside.?, 0..) |outside, i| {
        libs[i] = search_lib(mod, outside.lib);
    }
    return libs;
}

pub fn search_libs(mod: *const module.ModuleDescription_T, libs: []const[]const u8) [libs.len]?type {
    var loaded_libs = [_]?type {
        null
    } ** mod.libs.outside.?.len;
    for(libs, 0..) |outside, i| {
        loaded_libs[i] = search_lib(mod, outside);
    }
    return loaded_libs;
}

pub fn search_lib(mod: *const module.ModuleDescription_T, lib: []const u8) ?type {
    if(mod.libs.outside == null or mod.libs.outside.?.len == 0) @compileError(
        "modsys: " ++  mod.name ++ " request libs without outside lib"
    );
    const outside_lib: module.ModuleDescriptionLibOut_T = r: {
        for(mod.libs.outside.?) |outside_lib| {
            if(mem.eql(outside_lib.lib, lib, .{ .case = true }))
                break :r outside_lib;
        }
        @compileError(
            "modsys: " ++ lib ++ " " ++
            "lib requested does not exist in outside"
        );
    };
    const mod_found = find_module_by_name(outside_lib.mod)
        catch if(config.modules.options.IgnoreLibSearchNoExistentMod) return null else
            @compileError(
                "modsys: lib request by " ++ mod.name ++ " " ++
                "for module " ++ outside_lib.mod ++ ", " ++
                "but this mod is not added to the kernel! check the architecture " ++ @tagName(config.arch.options.Target) ++ " " ++
                "overrider and menuconfig to see if the module really exists"
            );
    const lib_found = find_module_lib_by_name(mod_found, outside_lib.lib)
        catch if(config.modules.options.IgnoreFaultNoExistentLib) return null else
            @compileError(
                "modsys: module " ++ mod.name ++ " " ++
                "is requesting " ++ outside_lib.lib ++ " " ++
                "lib for " ++ outside_lib.mod ++ " mod, " ++
                "but this lib does not exist"
            );
    if(lib_found.flags.enable == 0) @compileError(
        "modsys: lib " ++ lib_found.name ++ " " ++
        "of module " ++ mod_found.name ++ " " ++
        "is disable"
    );
    if(!mod_whitelisted(mod.name, lib_found)) @compileError(
        "modsys: module " ++ mod.name ++ " " ++
        "is not whitelisted in lib " ++ lib_found.name ++ " " ++
        "of module " ++ mod_found.name
    );
    return lib_found.lib;
}

fn find_module_by_name(mod_name: []const u8) anyerror!*const module.ModuleDescription_T {
    for(&modsys.saturn_modules) |*mod_desc| {
        if(mem.eql(mod_desc.name, mod_name, .{ .case = true}))
            return mod_desc;
    }
    return error.NoNFound;
}

fn find_module_lib_by_name(mod: *const module.ModuleDescription_T, lib_name: []const u8) anyerror!module.ModuleDescriptionLibMine_T {
    if(mod.libs.mines == null
        or mod.libs.outside.?.len == 0) return error.NoNFound;
    for(mod.libs.mines.?) |mine_lib| {
        if(mem.eql(lib_name, mine_lib.name, .{ .case = true }))
            return mine_lib;
    }
    return error.NoNFound;
}

fn mod_whitelisted(mod_name: []const u8, lib: module.ModuleDescriptionLibMine_T) bool {
    if(lib.flags.whitelist == 0) return true;
    if(lib.whitelist == null) return false;
    for(lib.whitelist.?) |whitelisted| {
        if(mem.eql(mod_name, whitelisted, .{ .case = true }))
            return true;
    }
    return false;
}
