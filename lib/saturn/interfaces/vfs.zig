// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vfs.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").core.vfs;
const interfaces: type = vfs.interfaces;
const memory: type = vfs.memory;

pub const Dentry_T: type = interfaces.Dentry_T;
pub const FileType_T: type = interfaces.FileType_T;
pub const InodeOp_T: type = interfaces.InodeOp_T;
pub const Superblock_T: type = interfaces.Superblock_T;
pub const VfsErr_T: type = interfaces.VfsErr_T;
