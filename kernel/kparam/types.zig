// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const hashtable: type = @import("root").lib.kernel.hash_table;

pub const KParamErr_T: type = error {
    SysParamNotFound,
    AllocatorInternalError,
    ParserSyntaxError,
    ParserInvalidValue,
    ParserMissingParameter,
    ParserMissingValue,
};

pub const Params_T: type = hashtable.HashMap(
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
