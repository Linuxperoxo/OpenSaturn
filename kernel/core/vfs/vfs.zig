// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vfs.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const main: type = @import("main.zig");
const types: type = @import("types.zig");

pub const uid_T: type = types.uid_T;
pub const gid_T: type = types.gid_T;
pub const mode_T: type = types.mode_T;
pub const FileType_T: type = types.FileType_T;
pub const Inode_T: type = types.Inode_T;
pub const InodeOp_T: type = types.InodeOp_T;
pub const Dentry_T: type = types.Dentry_T;
pub const Superblock_T: type = types.Superblock_T;
pub const VfsErr_T: type = types.VfsErr_T;

pub const write = main.write;
pub const read = main.read;
pub const unlink = main.unlink;
pub const mount = main.mount;
pub  const umount = main.umount;
