// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const main: type = @import("main.zig");
const types: type = @import("types.zig");

pub inline fn isValidMajor(major: types.Major) bool {
    return ((main.bitmap >> major) & 1) == 1;
}

pub inline fn isValidMinor(major: types.Major, minor: types.Minor) bool {
    return (majorPtr(major) catch return false).isValidMinor(minor);
}

pub inline fn minorOp(comptime op: enum { add, rm }, major: types.Major, minor: types.Minor) types.DevErr!void {
    const dev_info: *types.DevBranch = @constCast(try majorPtr(major));
    const dev: *types.Dev = @constCast(dev_info.dev);
    if(minor == 0) return types.DevErr.MainMinorOperation;
    switch(comptime op) {
        .add => {
            if(dev.flags.control.max == dev.flags.internal.total
                or dev.flags.control.minor == 0) return types.DevErr.MinorDenied;
            if(dev_info.isValidMinor(minor)) return types.DevErr.MinorCollision;
            dev_info.validadeMinor(minor);
            dev.flags.internal.total += 1;
        },

        .rm => {
            if(!dev_info.isValidMinor(minor)) return types.DevErr.MinorDoubleFree;
            dev_info.invalidateMinor(minor);
            dev.flags.internal.total -= 1;
        },
    }
}

pub inline fn majorPtr(major: types.Major) types.DevErr!*const types.DevBranch {
    return if(!isValidMajor(major)) types.DevErr.MajorNoNFound else
        &main.majors[major];
}

pub inline fn isValidOp(ops: *const types.DevOps, op: types.Ops) types.DevErr!void {
    return if(@field(ops, @tagName(op)) == null)
        types.DevErr.InvalidOperation;
}
