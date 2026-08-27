// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").interfaces.fs;
const vfs: type = @import("root").interfaces.vfs;
const ops: type = @import("ops.zig");
const types: type = @import("types.zig");

pub var devfs: fs.Fs = .{
    .name = "devfs",
    .mount = ops.devfsMount,
    .umount = ops.devfsUmount,
};

pub var devfs_superblock: vfs.Superblock = .{
    .magic = 0x703,
    .block_size = 0,
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_table_start = 0,
    .data_block_start = 0,
    .private_data = null,
    .inode_op = @constCast(&devfs_ops),
    .fs = &devfs,
};

pub var devfs_ops: vfs.InodeOp = .{
    .write = ops.write,
    .read = ops.read,
    .chmod = ops.chmod,
    .chown = ops.chown,
    .ioctl = ops.ioctl,
    .lookup = ops.lookup,
};
