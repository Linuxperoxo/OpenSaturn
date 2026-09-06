// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const list: type = @import("root").lib.kernel.linked_list;

const Dentry: type = interfaces.vfs.Dentry;
const Superblock: type = interfaces.vfs.Superblock;
const Inode: type = interfaces.vfs.Inode;

pub const List: type = list.buildList(*RootfsDentry);
pub const ListErr: type = List.ListErr;

pub const RootfsDentry: type = struct {
    dentry: ?*Dentry,
    childs: ?*List,
};

pub const RootfsErr: type = error {
    NonFound,
    DirectoryWithChilds,
    IteratorInternalError,
    ListInitFailed,
    AllocatorFailed,
    AttemptUmount,
    ListOperationFailed,
};

pub const RootfsPrivate: type = struct {
    parent: ?*RootfsDentry,
    self: *RootfsDentry,
};
