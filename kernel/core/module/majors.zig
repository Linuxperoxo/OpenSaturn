// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: majors.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("types.zig").Mod_T;
const Major_T: type = @import("majors/types.zig").Major_T;
const ModErr_T: type = @import("types.zig").ModErr_T;

const allMajors = [_]Major_T {
    @import("majors/drivers.zig").driversMajors,
    @import("majors/syscall.zig").syscallMajors,
    @import("majors/interrupt.zig").interruptMajors,
    @import("majors/irq.zig").irqMajors,
    @import("majors/filesystem.zig").filesystemMajors,
};

pub fn inMajor(M: *const Mod_T) ModErr_T!void {
    return @call(.never_inline, allMajors[@intFromEnum(M.type)].in, .{
        M,
    });
}

pub fn rmMajor(M: *const Mod_T) ModErr_T!void {
    return @call(.never_inline, allMajors[@intFromEnum(M.type)].rm, .{
        M,
    });
}
