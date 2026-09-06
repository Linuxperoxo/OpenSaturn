// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const vfs: type = @import("root").interfaces.vfs;
const rootfs: type = @import("rootfs.zig");
// required
const inode_utils: type = rootfs.__SaturnModuleDescription__.requestLib("inode-utils").?;

var inode: inode_utils = .{
    .current = 0,
};

pub inline fn obtainRootfsPrivate(dentry: *vfs.Dentry) *types.RootfsPrivate {
    if(dentry.d_sblock != null) return @alignCast(@ptrCast(dentry.d_sblock.?.private_data.?));
    return @alignCast(@ptrCast(dentry.d_private.?));
}

pub inline fn allocRootfsDentry() types.RootfsErr!*types.RootfsPrivate {
    const rootfs_private: *types.RootfsPrivate = try allocator.sba.allocOne(types.RootfsPrivate);
    errdefer allocator.sba.allocator.free(rootfs_private)
        catch {};
    rootfs_private.self = try allocator.sba.allocOne(types.RootfsDentry);
    rootfs_private.self.childs = null;
    return rootfs_private;
}

pub inline fn allocInode(uid: vfs.Uid, gid: vfs.Gid, mode: vfs.Mode) types.RootfsErr!*vfs.Inode {
    const new_inode: *vfs.Inode = inode.inodeGen(
        &allocator.sba.allocator,
        .directory,
        uid,
        gid,
        mode,
    ) catch return types.RootfsErr.AllocatorFailed;
    return new_inode;
}

pub inline fn allocName(name: []const u8) types.RootfsErr![]const u8 {
    const new_buffer: []u8 = allocator.sba.allocator.alloc(u8, name.len)
        catch return types.RootfsErr.AllocatorFailed;
    @memcpy(new_buffer, name);
    return new_buffer;
}
