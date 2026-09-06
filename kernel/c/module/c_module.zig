// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: c_module.zig │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").interfaces.module;
const c_types: type = @import("types.zig");

const CI8: type = c_types.utils.i8;
const CU8: type = c_types.utils.u8;

export fn inmod(mod: [*c]c_types.interfaces.Mod, ) callconv(.c) CI8 {
    if(mod == null)
        return c_types.utils.INTERNAL_ERR;
    @call(.never_inline, module.inmod, .{
        @as(module.Mod, @ptrCast(mod))
    }) catch |err| return switch(err) {
        module.ModErr.ListOperationError, module.ModErr.ListInitFailed => c_types.utils.ALLOC_ERR,
        else => c_types.utils.INTERNAL_ERR,
    };
    return 0;
}

export fn rmmod(mod: *module.Mod) callconv(.c) CI8 {
    _ = mod;
}

export fn srchmod(name: [*c]u8, mod_type: module.ModType) callconv(.c) *c_types.interfaces.Mod {
    _ = name;
    _ = mod_type;
}
