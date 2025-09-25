// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: filesystem.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Mod_T: type = @import("types.zig").Mod_T;
const Major_T: type = @import("types.zig").Major_T;
const ModErr_T: type = @import("types.zig").ModErr_T;
const MajorNode_T: type = @import("types.zig").MajorNode_T;

const Allocator = @import("allocator.zig");

pub const filesystemMajors: Major_T = .{
    .in = &@This().in,
    .rm = &@This().rm,
};

var majorsList: MajorNode_T = .{
    .data = null,
    .status = null,
    .next = null,
};

fn in(M: *const Mod_T) ModErr_T!void {
    @call(.never_inline, @import("root").interfaces.fs.registerfs, .{
        @as(*@import("root").interfaces.fs.Fs_T, @alignCast(@ptrCast(M.private))).*
    }) catch return ModErr_T.InternalError;
    var majorN: ?*MajorNode_T = majorsList.next;
    var majorC: *MajorNode_T = &majorsList;
    while(majorN) |_| {
        if(majorC.data.?.init == M.init) {
            return ModErr_T.IsInitialized;
        }
        majorC = majorC.next.?;
        majorN = majorN.?.next;
    }
    majorC.next = Allocator.alloc() catch return ModErr_T.AllocatorError;
    majorC.next.?.status = .running;
    majorC.next.?.data.? = M.*;
    return {};
}

fn rm(M: *const Mod_T) ModErr_T!void {
    var majorN: ?*MajorNode_T = majorsList.next;
    var majorP: *MajorNode_T = if(majorsList.status) |_| &majorsList else return {};
    x: {
        while(majorN) |_| {
            if(majorN.?.data.?.init == M.init) {
                break :x {};
            }
            majorP = majorP.next.?;
            majorN = majorN.?.next;
        }
        return ModErr_T.NoNInitialized;
    }
    const nextNode: ?*MajorNode_T = majorN.?.next;
    Allocator.free(majorP.next.?) catch return ModErr_T.InternalError;
    majorP.next = nextNode;
    return {};
}
