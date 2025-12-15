// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: exposed.zig   │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const aux: type = @import("aux_exposed.zig");
const module: type = @import("root").interfaces.module;
const config: type = @import("root").config;

pub fn search_by_libs(
    comptime mod: *const module.ModuleDescription_T
) anyerror!struct { [if(mod.libs.outside != null) mod.libs.outside.?.len else 0]?type, bool } {
    if(mod.libs.outside == null or mod.libs.outside.?.len == 0) @compileError(
        "modsys: " ++ mod.name ++ " request libs without outside lib"
    );
    var fault: bool = false;
    var libs = [_]?type {
        null
    } ** mod.libs.outside.?.len;
    for(0..libs.len) |i| {
        libs[i] = r: {
            if(aux.find_module_by_name(mod.libs.outside.?[i].mod)) |found| {
                const lib_found = aux.find_module_lib(found, mod.libs.outside.?[i].lib) catch {
                    if(config.modules.options.IgnoreFaultNoExistentLib)
                        break :r null;
                    @compileError(
                        "modsys: module " ++ mod.name ++ " " ++
                        "is requesting " ++ mod.libs.outside.?[i].lib ++ " " ++
                        "lib for " ++ mod.libs.outside.?[i].mod ++ " mod, " ++
                        "but this lib does not exist"
                    );
                };
                if(lib_found.flags.enable == 0) @compileError(
                    "modsys: lib " ++ lib_found.name ++ " " ++
                    "of module " ++ found.name ++ " " ++
                    "is disable"
                );
                if(!aux.mod_in_lib_whitelist(mod.name, lib_found)) @compileError(
                    "modsys: module " ++ mod.name ++ " " ++
                    "is not whitelisted in lib " ++ lib_found.name ++ " " ++
                    "of module " ++ found.name
                );
                break :r lib_found.lib;
            } else |_| {
                if(config.modules.options.IgnoreLibSearchNoExistentMod)
                    break :r null;
                @compileError(
                    "modsys: lib request by " ++ mod.name ++ " " ++
                    "for module " ++ mod.libs.outside.?[i].mod ++ ", " ++
                    "but is not added to the kernel! check the architecture " ++ @tagName(config.arch.options.Target) ++ " " ++
                    "overrider and menuconfig to see if the module really exists"
                );
            }
        };
        if(libs[i] == null)
            fault = true;
    }
    return .{
        libs,
        fault,
    };
}

pub fn module_abort_compile(
    comptime mod: *const module.ModuleDescription_T,
    comptime msg: []const u8,
) noreturn {
    @compileError(
        mod.name ++ ": " ++ msg
    );
}
