// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const aux: type = @import("aux.zig");
const types: type = @import("types.zig");
const c: type = @import("root").kernel.utils.c;
const allocator: type = @import("allocator.zig");
const module: type = @import("root").interfaces.module;

pub var fs_register: types.FsRegister_T = .{
    .fs = .{},
    .flags = .{
        .init = 0,
    },
};

pub fn register_fs(fs: *types.Fs_T) types.FsErr_T!void {
    try aux.check_init();
    if(aux.search_by_fs(fs, null)) |found| {
        const collided_fs, const collision = found;
        if(collision != null)
            @as(*u2, @alignCast(@ptrCast(&collided_fs.flags.internal.collision))).* = @as(u2, @intFromEnum(collision.?));
        return types.FsErr_T.FsCollision;
    } else |_| {
        fs_register.fs.push_in_list(&allocator.sba.allocator, fs)
            catch return types.FsErr_T.FsRegisterFailed;
    }
}

pub fn unregister_fs(fs: *types.Fs_T) types.FsErr_T!void {
    try aux.check_init();
    _ = try aux.search_by_fs(fs, null);
    return fs_register.fs.drop_on_list(
        (fs_register.fs.iterator_index() catch unreachable) - 1,
        &allocator.sba.allocator
    ) catch {
        return types.FsErr_T.FsRegisterFailed;
    };
}

pub fn search_fs(fs: []const u8) types.FsErr_T!*const types.Fs_T {
    try aux.check_init();
    const fs_found, _ = try aux.search_by_fs(null, fs);
    if(!c.c_bool(fs_found.flags.control.anon)) {
        return fs_found;
    }
    return types.FsErr_T.NoNFound;
}

