// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: smll.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Saturn Static Module Library Linker

const module: type = @import("root").interfaces.module;
const config: type = @import("root").config;
const mem: type = @import("root").lib.utils.mem;
const aux: type = @import("aux.zig");

pub fn search_all(comptime mod: *const module.ModuleDescription_T) struct { [
    if(mod.libs.outside == null) 0 else
        mod.libs.outside.?.len
]?type, bool } {
    if(mod.libs.outside == null or mod.libs.outside.?.len == 0) @compileError(
        "modsys: " ++  mod.name ++ " request libs without outside lib"
    );
    return comptime search_libs(mod, r: {
        var libs: [mod.libs.outside.?.len][]const u8 = undefined;
        for(0..libs.len) |i|
            libs[i] = mod.libs.outside.?[i].lib;
        break :r &libs;
    });
}

pub fn search_libs(mod: *const module.ModuleDescription_T, libs: []const[]const u8) struct { [libs.len]?type, bool } {
    var fault: bool = false;
    var loaded_libs = [_]?type {
        null
    } ** libs.len;
    for(libs, 0..) |outside, i| {
        loaded_libs[i] = search_lib(mod, outside);
        fault = if(loaded_libs[i] == null) true else fault;
    }
    return .{
        loaded_libs,
        fault,
    };
}

pub fn search_lib(mod: *const module.ModuleDescription_T, lib: []const u8) ?type {
    if(mod.libs.outside == null or mod.libs.outside.?.len == 0) @compileError(
        "modsys: \"" ++  mod.name ++ "\" request libs without outside lib"
    );
    const outside_lib = r: {
        for(mod.libs.outside.?) |outside_lib| {
            if(mem.eql(outside_lib.lib, lib, .{ .case = true }))
                break :r outside_lib;
        }
        @compileError(
            "modsys: \"" ++ lib ++ "\" " ++
            "lib requested does not exist in outside"
        );
    };
    const mod_found = aux.find_module_by_name(outside_lib.mod)
        catch if(outside_lib.flags.required == 0) return null else
            @compileError(
                "modsys: lib request by \"" ++ mod.name ++ "\" " ++
                "for module \"" ++ outside_lib.mod ++ "\", " ++
                "but this mod is not added to the kernel! check the architecture " ++ @tagName(config.arch.options.Target) ++ " " ++
                "overrider and menuconfig to see if the module really exists"
            );
    // procura pela definicao da lib de um modulo
    const lib_found = aux.find_module_lib_by_name(mod_found, outside_lib.lib)
        catch if(config.modules.options.IgnoreFaultNoExistentLib) return null else
            @compileError(
                "modsys: module \"" ++ mod.name ++ "\" " ++
                "is requesting lib \"" ++ outside_lib.lib ++ "\" " ++
                "for module \"" ++ outside_lib.mod ++ "\", " ++
                "but this lib does not exist"
            );
    if(lib_found.flags.enable == 0) @compileError(
        "modsys: lib \"" ++ lib_found.name ++ "\" " ++
        "of module \"" ++ mod_found.name ++ "\" " ++
        "is disable"
    );
    // verifica se o modulo esta na whitelist da lib
    if(!aux.mod_whitelisted(mod.name, lib_found)) @compileError(
        "modsys: module \"" ++ mod.name ++ "\" " ++
        "is not whitelisted in lib \"" ++ lib_found.name ++ "\" " ++
        "of module \"" ++ mod_found.name ++ "\""
    );
    if(aux.find_lib_version(outside_lib, lib_found)) |version_found| {
        if(version_found.flags.enable == 0) @compileError(
            "modsys: module \"" ++ mod.name ++ "\" is requesting lib" ++ " " ++
            "\"" ++ outside_lib.lib ++ "\" version \"" ++  outside_lib.version.tag ++ "\" " ++
            "for module \"" ++ outside_lib.mod ++ "\", but this lib version is disable"
        );
        // verifica se a o tipo do modulo e permitido pela lib
        if(!aux.valid_type_for_lib(mod, lib_found)) @compileError(
            "modsys: "
        );
        return version_found.lib;
    } else {
        if(config.modules.options.IgnoreVersionNoFound)
            return null;
        @compileError(
            "modsys: module \"" ++ mod.name ++ "\" is requesting lib" ++ " " ++
            "\"" ++ outside_lib.lib ++ "\" version \"" ++  outside_lib.version.tag ++ "\" " ++
            "for module \"" ++ outside_lib.mod ++ "\", but this lib version does not exist"
        );
    }
}
