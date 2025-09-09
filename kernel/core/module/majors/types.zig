// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Mod_T: type = @import("root").interfaces.module.types.Mod_T;
pub const ModErr_T: type = @import("root").interfaces.module.types.ModErr_T;
pub const ModType_T: type = @import("root").interfaces.module.types.ModType_T;
pub const Major_T: type = struct {
    in: *const fn(*const Mod_T) ModErr_T!void,
    rm: *const fn(*const Mod_T) ModErr_T!void,
};
pub const MajorNode_T: type = struct {
    data: ?Mod_T,
    status: ?enum { running, sleeping },
    next: ?*MajorNode_T,
};

