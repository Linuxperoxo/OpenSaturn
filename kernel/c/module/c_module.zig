// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: c_module.zig │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").interfaces.module;
const c_types: type = @import("types.zig");

const c_i8: type = c_types.utils.i8;
const c_u8: type = c_types.utils.u8;

export fn inmod(mod: [*c]c_types.interfaces.Mod_T, ) callconv(.c) c_i8 {
    if(mod == null)
        return c_types.utils.INTERNAL_ERR;
    @call(.never_inline, module.inmod, .{
        @as(module.Mod_T, @ptrCast(mod))
    }) catch |err| return switch(err) {
        module.ModErr_T.ListOperationError, module.ModErr_T.ListInitFailed => c_types.utils.ALLOC_ERR,
        else => c_types.utils.INTERNAL_ERR,
    };
    return 0;
}

export fn rmmod(mod: *module.Mod_T) callconv(.c) c_i8 {
    _ = mod;
}

export fn srchmod(name: [*c]u8, mod_type: module.ModType_T) callconv(.c) *c_types.interfaces.Mod_T {
    _ = name;
    _ = mod_type;
}


