// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const rootfs: type = @import("rootfs.zig");
const types: type = @import("types.zig");
const mem: type = @import("root").kernel.utils.mem;
const c: type = @import("root").kernel.utils.c;
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");
// required
const inode_utils: type = rootfs.__SaturnModuleDescription__.request_lib("inode-utils").?;

const Dentry_T: type = interfaces.vfs.Dentry_T;
const Superblock_T: type = interfaces.vfs.Superblock_T;
const FileType_T: type = interfaces.vfs.FileType_T;
const InodeOp_T: type = interfaces.vfs.InodeOp_T;
const Inode_T: type = interfaces.vfs.Inode_T;
const VfsErr_T: type = interfaces.vfs.VfsErr_T;
const Fs_T: type = interfaces.fs.Fs_T;
const FsErr_T: type = interfaces.fs.FsErr_T;
const uid_T: type = interfaces.vfs.uid_T;
const gid_T: type = interfaces.vfs.gid_T;
const mode_T: type = interfaces.vfs.mode_T;
const RootfsDentry_T: type = types.RootfsDentry_T;
const RootfsErr_T: type = types.RootfsErr_T;
const list_T: type = types.list_T;
const listErr_T: type = types.listErr_T;

pub var dir_inode_ops: InodeOp_T = .{
    .chmod = &chmod,
    .chown = &chown,
    .create = null,
    .iterator = null,
    .lookup = &lookup,
    .mkdir = &mkdir,
    .read = null,
    .unlink = &unlink,
    .write = null,
};

var superblock: Superblock_T = .{
    .fs = @alignCast(@ptrCast(&rootfs.rootfs.private)),
    .block_size = 0,
    .data_block_start = 0,
    .inode_table_start = 0,
    .magic = 0xAB00,
    .private_data = null,
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_op = &dir_inode_ops,
};

var inode: inode_utils = .{
    .current = 0,
};

pub fn rootfs_mount() anyerror!*const Superblock_T {
    return &superblock;
}

pub fn rootfs_umount()anyerror!void {
    // klog()
    return RootfsErr_T.AttemptUmount;
}

pub fn chmod(dentry: *Dentry_T, mode: mode_T) anyerror!void {
    @constCast(dentry.d_inode.?).mode = mode;
}

pub fn chown(dentry: *Dentry_T, uid: uid_T, gid: gid_T) anyerror!void {
    @constCast(dentry.d_inode.?).uid = uid;
    @constCast(dentry.d_inode.?).gid = gid;
}

pub fn lookup(parent: *Dentry_T, name: []const u8) anyerror!*Dentry_T {
}

pub fn mkdir(parent: *Dentry_T, name: []const u8, uid: uid_T, gid: gid_T, mode: mode_T) anyerror!void {
}

pub fn unlink(dentry: *Dentry_T) anyerror!void {
}
