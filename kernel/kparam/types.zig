// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const hashtable: type = @import("root").lib.utils.hashtable;

pub const KParamErr_T: type = error {
    SysParamNotFound,
    AllocatorInternalError,
};

pub const Params_T: type = hashtable.buildHashTable(
    []const u8,
    Value_T,
    8,
    null
);

pub const Value_T: type = enum(u1) {
    yes = 1,
    no = 0,
};

pub const Param_T: type = struct {
    param: []const u8,
    value: Value_T,
};
