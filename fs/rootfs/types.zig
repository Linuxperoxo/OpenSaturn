// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const list: type = @import("root").kernel.utils.list;

const Dentry_T: type = interfaces.vfs.Dentry_T;
const Superblock_T: type = interfaces.vfs.Superblock_T;
const Inode_T: type = interfaces.vfs.Inode_T;

pub const list_T: type = list.BuildList(*RootfsDentry_T);
pub const listErr_T: type = list_T.ListErr_T;

pub const RootfsDentry_T: type = struct {
    dentry: *Dentry_T,
    list: ?*list_T,
};

pub const RootfsErr_T: type = error {
    NonFound,
    IteratorInternalError,
    ListInitFailed,
    AllocatorFailed,
};

