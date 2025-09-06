// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fun.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const Driver_T: type = @import("types.zig").Driver_T;
const DriverErr_T: type = @import("types.zig").DriverErr_T;
const Ops_T: type = @import("types.zig").Ops_T;
const OpsErr_T: type = @import("types.zig").OpsErr_T;

const MajorNum_T: type = @import("types.zig").MajorNum_T;

const add = @import("core.zig").add;
const del = @import("core.zig").del;

pub fn register(comptime D: *const Driver_T) DriverErr_T!void {
    return @call(.always_inline, &add, .{
        D
    });
}

pub fn unregister(M: MajorNum_T) DriverErr_T!void {
    return @call(.always_inline, &del, .{
        M
    });
}
