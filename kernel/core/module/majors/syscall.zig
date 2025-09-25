// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: syscall.zig   │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const Mod_T: type = @import("types.zig").Mod_T;
const Major_T: type = @import("types.zig").Major_T;
const ModErr_T: type = @import("types.zig").ModErr_T;
const MajorNode_T: type = @import("types.zig").MajorNode_T;

const Allocator = @import("allocator.zig");

pub const syscallMajors: Major_T = .{
    .in = &@This().in,
    .rm = &@This().rm,
};

fn in(_: *const Mod_T) ModErr_T!void {

}

fn rm(_: *const Mod_T) ModErr_T!void {

}
