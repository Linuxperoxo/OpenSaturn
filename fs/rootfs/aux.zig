// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const vfs: type = @import("root").interfaces.vfs;
const main: type = @import("main.zig");

pub inline fn obtain_dentry_list(dentry: *vfs.Dentry_T) types.RootfsErr_T!*types.list_T {
    if(dentry.d_sblock != null) {
        if(dentry.d_sblock.?.private_data == null) {
             const list_ptr: *types.list_T = try allocator.sba.alloc_one(types.list_T);
             list_ptr.private = null;
             dentry.d_sblock.?.private_data = list_ptr;
        }
        return @ptrCast(@alignCast(@constCast(dentry.d_sblock.?.private_data.?)));
    }
    const rootfs_dentry_ptr: *types.RootfsDentry_T = @ptrCast(@alignCast(@constCast(dentry.d_private.?)));
    if(rootfs_dentry_ptr.list == null) {
        rootfs_dentry_ptr.list = try allocator.sba.alloc_one(types.list_T);
        rootfs_dentry_ptr.list.?.private = null;
    }
    return rootfs_dentry_ptr.list.?;
}

pub inline fn alloc_init_entry() types.RootfsErr_T!*types.RootfsDentry_T {
    const rootfs_entry = try allocator.sba.alloc_one(types.RootfsDentry_T);
    rootfs_entry.dentry = allocator.sba.alloc_one(vfs.Dentry_T) catch |err| {
        allocator.sba.allocator.free(rootfs_entry) catch {};
        return err;
    };
    rootfs_entry.dentry.d_op = &main.dir_inode_ops;
    rootfs_entry.dentry.child = null;
    rootfs_entry.dentry.parent = null;
    rootfs_entry.dentry.younger_brother = null;
    rootfs_entry.dentry.older_brother = null;
    rootfs_entry.dentry.d_private = rootfs_entry;
    rootfs_entry.list = null;
    return rootfs_entry;
}
