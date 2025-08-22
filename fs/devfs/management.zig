// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Dentry_T: type = @import("root").core.vfs.interfaces.Dentry_T;
const Superblock_T: type = @import("root").core.vfs.interfaces.Superblock_T;
const FileType_T: type = @import("root").core.vfs.interfaces.FileType_T;
const InodeOp_T: type = @import("root").core.vfs.interfaces.InodeOp_T;
const Inode_T: type = @import("root").core.vfs.interfaces.Inode_T;
const VfsErr_T: type = @import("root").core.vfs.interfaces.VfsErr_T;

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

pub fn devfs_mount() FsErr_T!Superblock_T {
    
}

pub fn devfs_umount() FsErr_T!void {

}
