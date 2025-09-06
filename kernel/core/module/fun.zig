// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fun.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Internal
const Mod_T: type = @import("types.zig").Mod_T;
const ModErr_T: type = @import("types.zig").ModErr_T;

const inMajor = @import("majors.zig").inMajor;
const rmMajor = @import("majors.zig").rmMajor;

pub fn inmod(
    M: *const Mod_T
) ModErr_T!void {
    return @call(.never_inline, &inMajor, .{
        M
    });
}

pub fn rmmod(
    M: *const Mod_T
) ModErr_T!void {
    return @call(.never_inline, &rmMajor, .{
        M
    });
}
