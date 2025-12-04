// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const main: type = @import("main.zig");
const std: type = @import("std");

var geral_op: types.InodeOp_T = .{
    .lookup = &opaque {
        pub fn lookup(_: *types.Dentry_T, name: []const u8) anyerror!*types.Dentry_T {
            if(name[0] == 'd') return &dev_dentry;
            if(name[0] != 's' and name[0] != 'n') return types.VfsErr_T.NoNFound;
            if(name[0] == 's') return &sda_dentry;
            if(name[0] == 'n') return &nvme_entry;
            unreachable;
            
        }
    }.lookup,
    .create = null,
    .iterator = null,
    .mkdir = null,
    .unlink = null,
};

var dev_dentry: types.Dentry_T = .{
    .d_name = "dev",
    .d_inode = &geral_inode,
    .d_sblock = null,
    .d_op = &geral_op,
    .d_private = null,
    .child = null,
    .parent = null,
    .brother = null,
};

var sda_dentry: types.Dentry_T = .{
    .d_name = "sba",
    .d_inode = &geral_inode,
    .d_sblock = null,
    .d_private = null,
    .d_op = &geral_op,
    .child = null,
    .parent = null,
    .brother = null,
};

var nvme_entry: types.Dentry_T = .{
    .d_name = "nvme",
    .d_inode = &geral_inode,
    .d_sblock = null,
    .d_private = null,
    .d_op = &geral_op,
    .child = null,
    .parent = null,
    .brother = null,
};

var geral_inode: types.Inode_T = .{
    .data_block = 10,
    .gid = 10,
    .ino = 10,
    .mode = 10,
    .nlinks = 10,
    .type = .directory,
    .uid = 10,
};

var sblock: types.Superblock_T = .{
    .root_inode = &geral_inode,
    .block_size = 10,
    .data_block_start = 10,
    .inode_table_start = 10,
    .magic = 10,
    .private_data = null,
    .total_blocks = 10,
    .total_inodes = 10,
};

test "VFS Tree" {
    const root_branch = try main.resolve_path("/", null);
    root_branch.d_sblock = &sblock;
    root_branch.d_op = dev_dentry.d_op.?;
    root_branch.child = &dev_dentry;
    dev_dentry.parent = root_branch;
    _ = try main.resolve_path("/dev/sba", null);
    _ = try main.resolve_path("/dev/nvme", null);
    std.debug.print("{s}, {s}, {s}, {s}\n", .{
        root_branch.d_name,
        root_branch.child.?.d_name,
        root_branch.child.?.child.?.d_name,
        root_branch.child.?.child.?.brother.?.d_name
    });
}
