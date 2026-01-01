// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const vfs: type = @import("root").interfaces.vfs;
const main: type = @import("main.zig");
const mem: type = @import("root").kernel.utils.mem;
const rootfs: type = @import("rootfs.zig");
// required
const inode_utils: type = rootfs.__SaturnModuleDescription__.request_lib("inode-utils").?;

var inode: inode_utils = .{
    .current = 0,
};

pub inline fn obtain_rootfs_private(dentry: *vfs.Dentry_T) *types.RootfsPrivate_T {
    if(dentry.d_sblock != null) return @alignCast(@ptrCast(dentry.d_sblock.?.private_data.?));
    return @alignCast(@ptrCast(dentry.d_private.?));
}

pub inline fn alloc_rootfs_dentry() types.RootfsErr_T!*types.RootfsPrivate_T {
    const rootfs_private: *types.RootfsPrivate_T = try allocator.sba.alloc_one(types.RootfsPrivate_T);
    errdefer allocator.sba.allocator.free(rootfs_private)
        catch {};
    rootfs_private.self = try allocator.sba.alloc_one(types.RootfsDentry_T);
    rootfs_private.self.childs = null;
    return rootfs_private;
}

pub inline fn alloc_inode(uid: vfs.uid_T, gid: vfs.gid_T, mode: vfs.mode_T) types.RootfsErr_T!*vfs.Inode_T {
    const new_inode: *vfs.Inode_T = inode.inode_gen(
        &allocator.sba.allocator,
        .directory,
        uid,
        gid,
        mode,
    ) catch return types.RootfsErr_T.AllocatorFailed;
    return new_inode;
}

pub inline fn alloc_name(name: []const u8) types.RootfsErr_T![]const u8 {
    const new_buffer: []u8 = (allocator.sba.allocator.alloc(u8, name.len)
        catch return types.RootfsErr_T.AllocatorFailed)[0..name.len];
    @memcpy(new_buffer, name);
    return new_buffer;
}
