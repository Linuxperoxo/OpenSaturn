// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Dentry_T: type = @import("root").interfaces.vfs.Dentry_T;
const Superblock_T: type = @import("root").interfaces.vfs.Superblock_T;
const FileType_T: type = @import("root").interfaces.vfs.FileType_T;
const InodeOp_T: type = @import("root").interfaces.vfs.InodeOp_T;
const Inode_T: type = @import("root").interfaces.vfs.Inode_T;
const VfsErr_T: type = @import("root").interfaces.vfs.VfsErr_T;
const FsErr_T: type = @import("root").interfaces.fs.FsErr_T;

const rootfsSuperblock: *Superblock_T = @constCast(&Superblock_T {
    .magic = 0x703,
    .block_size = 0,
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_table_start = 0,
    .data_block_start = 0,
    .root_inode = null,
    .private_data = null,
});

pub fn devfs_mount() anyerror!*const Superblock_T {
    return error.InternalError;
}

pub fn devfs_umount() anyerror!void {
    return error.InternalError;
}
