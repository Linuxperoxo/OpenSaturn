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
    const rootfs_dentry_ptr: *types.RootfsDentry_T = @as(*types.RootfsPrivate_T, @ptrCast(@alignCast(@constCast(dentry.d_private.?)))).self;
    if(rootfs_dentry_ptr.list == null) {
        rootfs_dentry_ptr.list = try allocator.sba.alloc_one(types.list_T);
        rootfs_dentry_ptr.list.?.private = null;
    }
    return rootfs_dentry_ptr.list.?;
}

pub inline fn alloc_init_entry() types.RootfsErr_T!*types.RootfsDentry_T {
    const rootfs_private = try allocator.sba.alloc_one(types.RootfsPrivate_T);
    errdefer allocator.sba.allocator.free(rootfs_private) catch {};
    rootfs_private.self = try allocator.sba.alloc_one(types.RootfsDentry_T);
    errdefer allocator.sba.allocator.free(rootfs_private.self) catch {};
    rootfs_private.self.dentry = try allocator.sba.alloc_one(vfs.Dentry_T);
    rootfs_private.self.dentry.d_op = &main.dir_inode_ops;
    rootfs_private.self.dentry.child = null;
    rootfs_private.self.dentry.parent = null;
    rootfs_private.self.dentry.younger_brother = null;
    rootfs_private.self.dentry.older_brother = null;
    rootfs_private.self.dentry.d_private = rootfs_private;
    rootfs_private.self.list = null;
    return rootfs_private.self;
}

pub inline fn cast_private(dentry: *vfs.Dentry_T) *types.RootfsPrivate_T {
    return @ptrCast(@alignCast(dentry.d_private.?));
}
