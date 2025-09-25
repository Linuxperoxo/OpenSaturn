// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: drivers.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("types.zig").Mod_T;
const Major_T: type = @import("types.zig").Major_T;
const ModErr_T: type = @import("types.zig").ModErr_T;
const MajorNode_T: type = @import("types.zig").MajorNode_T;

pub const driversMajors: Major_T = .{
    .in = &@This().in,
    .rm = &@This().rm,
};

const majorsList: MajorNode_T = .{
    .data = null,
    .status = null,
    .next = null,
};

fn in(_: *const Mod_T) ModErr_T!void {

}

fn rm(_: *const Mod_T) ModErr_T!void {

}
