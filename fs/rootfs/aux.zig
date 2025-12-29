// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const vfs: type = @import("root").interfaces.vfs;
const main: type = @import("main.zig");
const mem: type = @import("root").kernel.utils.mem;

pub inline fn obtain_rootfs_dentry(dentry: *vfs.Dentry_T) types.RootfsErr_T!*types.RootfsDentry_T {
}

pub inline fn alloc_init_entry() types.RootfsErr_T!*types.RootfsDentry_T {
}

pub inline fn cast_private(dentry: *vfs.Dentry_T) *types.RootfsPrivate_T {
    return @ptrCast(@alignCast(dentry.d_private.?));
}
