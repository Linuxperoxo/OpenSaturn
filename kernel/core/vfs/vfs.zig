// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vfs.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const main: type = @import("main.zig");
const types: type = @import("types.zig");

pub const Uid: type = types.Uid;
pub const Gid: type = types.Gid;
pub const Mode: type = types.Mode;
pub const FileType: type = types.FileType;
pub const Inode: type = types.Inode;
pub const InodeOp: type = types.InodeOp;
pub const Dentry: type = types.Dentry;
pub const Superblock: type = types.Superblock;
pub const VfsErr: type = types.VfsErr;

pub const r: u3 = types.r;
pub const w: u3 = types.w;
pub const x: u3 = types.x;

pub const write = main.write;
pub const read = main.read;
pub const unlink = main.unlink;
pub const mount = main.mount;
pub const umount = main.umount;
pub const create = main.create;
pub const mkdir = main.mkdir;
pub const chmod = main.chmod;
pub const chown = main.chown;
pub const touch = main.touch;
