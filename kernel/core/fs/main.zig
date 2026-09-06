// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const aux: type = @import("aux.zig");
const types: type = @import("types.zig");
const c: type = @import("root").lib.kernel.c;
const allocator: type = @import("allocator.zig");
const module: type = @import("root").interfaces.module;

pub var fs_register: types.FsRegister = .{
    .fs = .{},
    .flags = .{
        .init = 0,
    },
};

pub fn registerFs(fs: *types.Fs) types.FsErr!void {
    try aux.checkInit();
    if(aux.searchByFs(fs, null)) |found| {
        const collided_fs, const collision = found;
        if(collision != null)
            @as(*u2, @alignCast(@ptrCast(&collided_fs.flags.internal.collision))).* = @as(u2, @intFromEnum(collision.?));
        return types.FsErr.FsCollision;
    } else |_| {
        fs_register.fs.pushInList(&allocator.sba.allocator, fs)
            catch return types.FsErr.FsRegisterFailed;
    }
}

pub fn unregisterFs(fs: *types.Fs) types.FsErr!void {
    try aux.checkInit();
    _ = try aux.searchByFs(fs, null);
    return fs_register.fs.dropOnList(
        (fs_register.fs.iteratorIndex() catch unreachable) - 1,
        &allocator.sba.allocator
    ) catch {
        return types.FsErr.FsRegisterFailed;
    };
}

pub fn searchFs(fs: []const u8) types.FsErr!*const types.Fs {
    try aux.checkInit();
    const fs_found, _ = try aux.searchByFs(null, fs);
    if(!c.cBool(fs_found.flags.control.anon)) {
        return fs_found;
    }
    return types.FsErr.NoNFound;
}
