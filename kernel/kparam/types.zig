// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const hashtable: type = @import("root").lib.kernel.hash_table;

pub const KParamErr: type = error {
    SysParamNotFound,
    AllocatorInternalError,
    ParserSyntaxError,
    ParserInvalidValue,
    ParserMissingParameter,
    ParserMissingValue,
};

pub const Params: type = hashtable.hashMap(
    []const u8,
    Value,
    8,
    null
);

pub const Value: type = enum(u1) {
    yes = 1,
    no = 0,
};

pub const Param: type = struct {
    param: []const u8,
    value: Value,
};
