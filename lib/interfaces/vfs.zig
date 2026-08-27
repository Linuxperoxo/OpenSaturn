// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vfs.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").core.vfs;

pub const Uid: type = vfs.Uid;
pub const Gid: type = vfs.Gid;
pub const Mode: type = vfs.Mode;
pub const FileType: type = vfs.FileType;
pub const Inode: type = vfs.Inode;
pub const InodeOp: type = vfs.InodeOp;
pub const Dentry: type = vfs.Dentry;
pub const Superblock: type = vfs.Superblock;
pub const VfsErr: type = vfs.VfsErr;

pub const r: u3 = vfs.r;
pub const w: u3 = vfs.w;
pub const x: u3 = vfs.x;

pub const write = vfs.write;
pub const read = vfs.read;
pub const unlink = vfs.unlink;
pub const mount = vfs.mount;
pub const umount = vfs.umount;
pub const create = vfs.create;
pub const mkdir = vfs.mkdir;
pub const chmod = vfs.chmod;
pub const chown = vfs.chown;
pub const touch = vfs.touch;
