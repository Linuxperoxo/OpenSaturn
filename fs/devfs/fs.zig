// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").interfaces.fs;
const vfs: type = @import("root").interfaces.vfs;
const ops: type = @import("ops.zig");

pub var devfs: fs.Fs_T = .{
    .name = "devfs",
    .mount = ops.devfs_mount,
    .umount = ops.devfs_umount,
    .flags = .{
        .control = .{
            .nomount = 0,
            .noumount = 0,
            .readonly = 0,
            .anon = 0,
        },
        .internal = .{},
    },
};

pub const devfs_superblock: vfs.Superblock_T = .{
    .magic = 0x703,
    .block_size = 0,
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_table_start = 0,
    .data_block_start = 0,
    .private_data = null,
    .inode_op = &devfs_ops,
    .fs = devfs,
};

pub const devfs_ops: vfs.InodeOp_T = .{
    .write = ops.write,
    .read = ops.read,
    .chmod = ops.chmod,
    .chown = ops.chown,
    .ioctl = ops.ioctl,
    .lookup = ops.lookup,
};
