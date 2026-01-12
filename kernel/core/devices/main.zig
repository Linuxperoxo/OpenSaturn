// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const aux: type = @import("aux.zig");
const mem: type =  @import("root").lib.utils.mem;
const builtin: type = @import("builtin");

pub var majors: [@bitSizeOf(usize)]types.DevBranch_T = undefined;
pub var bitmap: usize = 0;

pub fn dev_add(major: types.Major_T, dev: *const types.Dev_T) types.DevErr_T!void {
    if(aux.is_valid_major(major)) return types.DevErr_T.MajorCollision;
    bitmap |= @as(@TypeOf(bitmap), 1) << major;
    majors[major].dev = dev;
    if(!builtin.is_test) {
        majors[major].minors = mem.zeroe_mem(majors[major].minors);
    } else {
        for(1..16) |i| {
            majors[major].minors[i] = 0;
        }
    }
    majors[major].minors[0] = 1;
}

pub fn dev_rm(major: types.Major_T) types.DevErr_T!void {
    bitmap &= ~major;
}

pub fn dev_minor_add(major: types.Major_T, minor: types.Minor_T) types.DevErr_T!void {
    return aux.minor_op(.add, major, minor);
}

pub fn dev_minor_rm(major: types.Major_T, minor: types.Minor_T) types.DevErr_T!void {
    return aux.minor_op(.rm, major, minor);
}

pub fn valid_major(major: types.Major_T) bool {
    return aux.is_valid_major(major);
}

pub fn valid_minor(major: types.Major_T, minor: types.Minor_T) bool {
    return if(!aux.is_valid_major(major)) false else
        majors[major].is_valid_minor(minor);
}

pub fn next_major() types.DevErr_T!types.Major_T {
    if((~bitmap) == 0) return types.DevErr_T.WithoutMajor;
    var map: usize = bitmap;
    var bit: usize = 0;
    while(map > 0) : ({ map >>= 1; bit += 1; }) {
        if((map & 1) == 0)
            return bit;
    }
    unreachable;
}

pub fn next_minor(major: types.Major_T) types.DevErr_T!types.Minor_T {
    _ = major;
}
