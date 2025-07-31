// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const ModuleInfo_T: type = struct {
    name: []const u8,
    optional: bool,
};

pub const ModuleResolved_T: type = struct {
    pub const Action_T: type = enum {
        include,
        skip,
        undef,
    };

    info: *const ModuleInfo_T,
    action: Action_T,
};

pub const ModuleInfoResolvedInit_T: type = struct {
    resolved: *const ModuleResolved_T,
    init: *const fn() anyerror!void,
};

