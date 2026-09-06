// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const aux: type = @import("aux.zig");
const mem: type =  @import("root").lib.kernel.mem;
const builtin: type = @import("builtin");

pub var majors: [@bitSizeOf(usize)]types.DevBranch = undefined;
pub var bitmap: usize = 0;

pub inline fn devInfo(major: types.Major, comptime field: enum { name, type }) types.DevErr!@FieldType(types.Dev, @tagName(field)) {
    if(!aux.isValidMajor(major)) return types.DevErr.MajorNoNFound;
    return @field(majors[major].dev, @tagName(field));
}

pub noinline fn devAdd(major: types.Major, dev: *const types.Dev) types.DevErr!void {
    if(aux.isValidMajor(major)) return types.DevErr.MajorCollision;
    bitmap |= @as(@TypeOf(bitmap), 1) << major;
    majors[major].dev = dev;
    majors[major].minors[0] = 1;
    for(1..16) |i|
        majors[major].minors[i] = 0;
}

pub inline fn devRm(major: types.Major, dev: *const types.Dev) types.DevErr!void {
    if((bitmap >> major) == 0 or majors[major].dev != dev)
        return types.DevErr.MajorNoNFound;
    bitmap &= ~major;
}

pub noinline fn devMinorAdd(major: types.Major, minor: types.Minor) types.DevErr!void {
    return aux.minorOp(.add, major, minor);
}

pub noinline fn devMinorRm(major: types.Major, minor: types.Minor) types.DevErr!void {
    return aux.minorOp(.rm, major, minor);
}

pub noinline fn validMajor(major: types.Major) bool {
    return aux.isValidMajor(major);
}

pub noinline fn validMinor(major: types.Major, minor: types.Minor) bool {
    return if(!aux.isValidMajor(major)) false else
        majors[major].isValidMinor(minor);
}

pub noinline fn nextMajor() types.DevErr!types.Major {
    if((~bitmap) == 0) return types.DevErr.WithoutMajor;
    var map: usize = bitmap;
    var bit: types.Major = 0;
    while(map > 0) : ({ map >>= 1; bit += 1; }) {
        if((map & 1) == 0)
            return bit;
    }
    unreachable;
}

pub noinline fn nextMinor(major: types.Major) types.DevErr!types.Minor {
    _ = major;
}
