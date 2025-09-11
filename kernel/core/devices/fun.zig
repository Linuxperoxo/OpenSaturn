// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fun.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Dev_T: type = @import("types.zig").Dev_T;
const DevErr_T: type = @import("types.zig").DevErr_T;
const MinorNum_T: type = @import("types.zig").MinorNum_T;

const add = @import("core.zig").add;
const del = @import("core.zig").del;

pub fn register(
    D: *const Dev_T,
) DevErr_T!void {
    return @call(.always_inline, &add, .{
        D
    });
}

pub fn unregister(
    M: MinorNum_T
) DevErr_T!void {
    return @call(.always_inline, &del, .{
        M
    });
}
