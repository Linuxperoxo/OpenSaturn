// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const vfs: type = @import("root").interfaces.vfs;

pub inline fn obtain_rootfs_d(dentry: *vfs.Dentry_T) *types.RootfsDentry_T {
    if(dentry.d_sblock != null)
        return @alignCast(@ptrCast(@constCast(dentry.d_sblock.?.private_data.?)));
    return @alignCast(@ptrCast(@constCast(dentry.d_private.?)));
}

pub inline fn alloc_init_entry() types.RootfsErr_T!*types.RootfsDentry_T {
    const rootfs_entry = try allocator.sba.alloc_one(types.RootfsDentry_T);
    rootfs_entry.dentry = allocator.sba.alloc_one(vfs.Dentry_T) catch |err| {
        allocator.sba.allocator.free(rootfs_entry) catch {};
        return err;
    };
    rootfs_entry.dentry.child = null;
    rootfs_entry.dentry.parent = null;
    rootfs_entry.dentry.younger_brother = null;
    rootfs_entry.dentry.older_brother = null;
    rootfs_entry.dentry.d_private = rootfs_entry;
    rootfs_entry.list = null;
    return rootfs_entry;
}
