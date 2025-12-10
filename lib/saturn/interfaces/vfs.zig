// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vfs.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").core.vfs;

pub const uid_T: type = vfs.uid_T;
pub const gid_T: type = vfs.gid_T;
pub const mode_T: type = vfs.mode_T;
pub const FileType_T: type = vfs.FileType_T;
pub const Inode_T: type = vfs.Inode_T;
pub const InodeOp_T: type = vfs.InodeOp_T;
pub const Dentry_T: type = vfs.Dentry_T;
pub const Superblock_T: type = vfs.Superblock_T;
pub const VfsErr_T: type = vfs.VfsErr_T;

pub const write = vfs.write;
pub const read = vfs.read;
pub const unlink = vfs.unlink;
pub const mount = vfs.mount;
pub const umount = vfs.umount;
pub const create = vfs.create;
pub const mkdir = vfs.mkdir;
pub const chmod = vfs.chmod;
pub const chown = vfs.chown;
