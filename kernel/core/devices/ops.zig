// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ops.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const MinorNum_T: type = @import("types.zig").MinorNum_T;
const MajorNum_T: type = @import("root").interfaces.drivers.MajorNum_T;
const Dev_T: type = @import("types.zig").Dev_T;
const DevErr_T: type = @import("types.zig").DevErr_T;
const DriversOps: type = @import("root").interfaces.drivers.fun.ops;

const exist = @import("core.zig").exist;

pub fn open(Ma: MajorNum_T, Mi: MinorNum_T) DevErr_T!void {
    const ma, const mi, _ = @call(.never_inline, &exist, .{
        Ma, Mi
    }).* catch |err| return err;
    @call(.never_inline, &DriversOps.open, .{
        ma, mi
    }) catch return DevErr_T.MajorReturnError;
}

pub fn close(Ma: MajorNum_T, Mi: MajorNum_T) void {
    const ma, const mi, _ = @call(.never_inline, &exist, .{
        Ma, Mi
    }).* catch |err| return err;
    @call(.never_inline, &DriversOps.open, .{
        ma, mi
    }) catch return DevErr_T.MajorReturnError;
}

pub fn minor(Ma: MajorNum_T, Mi: MinorNum_T) DevErr_T!void {
    const ma, const mi, _ = @call(.never_inline, &exist, .{
        Ma, Mi
    }).* catch |err| return err;
    @call(.never_inline, &DriversOps.open, .{
        ma, mi
    }) catch return DevErr_T.MajorReturnError;
}

pub fn read(Ma: MajorNum_T, Mi: MinorNum_T, offset: usize) []u8 {
    const ma, const mi, _ = @call(.never_inline, &exist, .{
        Ma, Mi
    }).* catch |err| return err;
    return @call(.never_inline, &DriversOps.open, .{
        ma, mi, offset
    }) catch return DevErr_T.MajorReturnError;
}

pub fn write(Ma: MajorNum_T, Mi: MinorNum_T, data: []const u8) void {
    const ma, const mi, _ = @call(.never_inline, &exist, .{
        Ma, Mi
    }).* catch |err| return err;
    @call(.never_inline, &DriversOps.write, .{
        ma, mi, data
    }) catch return DevErr_T.MajorReturnError;
}

pub fn ioctrl(Ma: MajorNum_T, Mi: MinorNum_T, command: usize, data: usize) DevErr_T!usize {
    const ma, const mi, _ = @call(.never_inline, &exist, .{
        Ma, Mi
    }).* catch |err| return err;
    return @call(.never_inline, &DriversOps.ioctrl, .{
        ma, mi, command, data
    }) catch return DevErr_T.MajorReturnError;
}
