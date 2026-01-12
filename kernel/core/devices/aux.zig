// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const main: type = @import("main.zig");
const types: type = @import("types.zig");

pub inline fn is_valid_major(major: types.Major_T) bool {
    return ((main.bitmap >> major) & 1) == 1;
}

pub inline fn is_valid_minor(major: types.Major_T, minor: types.Minor_T) bool {
    return (major_ptr(major) catch return false).is_valid_minor(minor);
}

pub inline fn minor_op(comptime op: enum { add, rm }, major: types.Major_T, minor: types.Minor_T) types.DevErr_T!void {
    const dev_info: *types.DevBranch_T = @constCast(try major_ptr(major));
    const dev: *types.Dev_T = @constCast(dev_info.dev);
    if(minor == 0) return types.DevErr_T.MainMinorOperation;
    switch(comptime op) {
        .add => {
            if(dev.flags.control.max == dev.flags.internal.total
                or dev.flags.control.minor == 0) return types.DevErr_T.MinorDenied;
            if(dev_info.is_valid_minor(minor)) return types.DevErr_T.MinorCollision;
            dev_info.validade_minor(minor);
            dev.flags.internal.total += 1;
        },

        .rm => {
            if(!dev_info.is_valid_minor(minor)) return types.DevErr_T.MinorDoubleFree;
            dev_info.invalidate_minor(minor);
            dev.flags.internal.total -= 1;
        },
    }
}

pub inline fn major_ptr(major: types.Major_T) types.DevErr_T!*const types.DevBranch_T {
    return if(!is_valid_major(major)) types.DevErr_T.MajorNoNFound else
        &main.majors[major];
}

pub inline fn is_valid_op(ops: *const types.DevOps_T, op: types.Ops_T) types.DevErr_T!void {
    return if(@field(ops, @tagName(op)) == null)
        types.DevErr_T.InvalidOperation;
}
