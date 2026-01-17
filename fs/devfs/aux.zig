// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").interfaces.vfs;
const types: type = @import("types.zig");

pub fn dentry_device_info(dentry: *vfs.Dentry_T) types.DevfsErr_T!*const types.DevfsPrivate_T {
    if(dentry.d_private == null)
        return types.DevfsErr_T.CorruptDentry;
    return @ptrCast(@alignCast(dentry.d_private.?));
}
