// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
const types: type = @import("types.zig");
const main: type = @import("main.zig");
const aux: type = @import("aux.zig");

const OpCall_T: type = struct {
    read: bool = false,
    write: bool = false,
    created: bool = false,
};

var nvme: OpCall_T = .{};
var sba: OpCall_T = .{};
var self: OpCall_T = .{};
var pid0: OpCall_T = .{};

const all_call = [_]*const OpCall_T {
    &nvme,
    &sba,
    &self,
    &pid0
};

var dev_dentry: types.Dentry_T = .{
    .d_name = "dev",
    .d_inode = &dir_inode,
    .d_sblock = null,
    .d_op = &types.InodeOp_T {
        .lookup = &opaque {
            pub fn lookup(_: *types.Dentry_T, name: []const u8) anyerror!*types.Dentry_T {
                if(name[0] == 's' and sba.created) return &sda_dentry;
                if(name[0] == 'n' and nvme.created) return &nvme_dentry;
                return types.VfsErr_T.NoNFound;
            }
        }.lookup,
        .create = &opaque {
            pub fn create(_: *types.Dentry_T, name: []const u8, _: types.uid_T, _: types.gid_T, _: types.mode_T) anyerror!void {
                if(name[0] == 's') sba.created = true;
                if(name[0] == 'n') nvme.created = true;
            }
        }.create,
        .iterator = null,
        .mkdir = null,
        .read = null,
        .write = null,
        .unlink = null,
        .chmod = null,
        .chown = null,
    },
    .d_private = null,
    .child = null,
    .parent = null,
    .younger_brother = null,
    .older_brother = null,
    .private = null,
};

var proc_dentry: types.Dentry_T = .{
    .d_name = "proc",
    .d_inode = &dir_inode,
    .d_sblock = null,
    .d_op = &types.InodeOp_T {
        .lookup = &opaque {
            pub fn lookup(_: *types.Dentry_T, name: []const u8) anyerror!*types.Dentry_T {
                if(name[0] == 's' and self.created) return &self_dentry;
                if(name[0] == '0' and pid0.created) return &pid0_dentry;
                return types.VfsErr_T.NoNFound;
            }
        }.lookup,
        .create = &opaque {
            pub fn create(_: *types.Dentry_T, name: []const u8, _: types.uid_T, _: types.gid_T, _: types.mode_T) anyerror!void {
                if(name[0] == 's') self.created = true;
                if(name[0] == '0') pid0.created = true;
            }
        }.create,
        .iterator = null,
        .mkdir = null,
        .read = null,
        .write = null,
        .unlink = null,
        .chmod = null,
        .chown = null,
    },
    .d_private = null,
    .child = null,
    .parent = null,
    .younger_brother = null,
    .older_brother = null,
    .private = null,
};

var sda_dentry: types.Dentry_T = .{
    .d_name = "sba",
    .d_inode = &block_inode,
    .d_sblock = null,
    .d_private = null,
    .d_op = &types.InodeOp_T {
        .lookup = null,
        .create = null,
        .iterator = null,
        .mkdir = null,
        .read = &opaque {
            pub fn read(_: *types.Dentry_T) anyerror![]u8 {
               sba.read = true;
               return @constCast("Hello, World!");
            }
        }.read,
        .write = &opaque {
            pub fn write(_: *types.Dentry_T, _: []const u8) anyerror!void {
               sba.write = true;
            }
        }.write,
        .unlink = null,
        .chmod = null,
        .chown = null,
    },
    .child = null,
    .parent = null,
    .younger_brother = null,
    .older_brother = null,
    .private = null,
};

var self_dentry: types.Dentry_T = .{
    .d_name = "self", // FIXME: renomear causa um segfault
    .d_inode = &block_inode,
    .d_sblock = null,
    .d_private = null,
    .d_op = &types.InodeOp_T {
        .lookup = null,
        .create = null,
        .iterator = null,
        .mkdir = null,
        .read = &opaque {
            pub fn read(_: *types.Dentry_T) anyerror![]u8 {
               self.read = true;
               return @constCast("Hello, World!");
            }
        }.read,
        .write = &opaque {
            pub fn write(_: *types.Dentry_T, _: []const u8) anyerror!void {
               self.write = true;
            }
        }.write,
        .unlink = null,
        .chmod = null,
        .chown = null,
    },
    .child = null,
    .parent = null,
    .younger_brother = null,
    .older_brother = null,
    .private = null,
};

var pid0_dentry: types.Dentry_T = .{
    .d_name = "0",
    .d_inode = &block_inode,
    .d_sblock = null,
    .d_private = null,
    .d_op = &types.InodeOp_T {
        .lookup = null,
        .create = null,
        .iterator = null,
        .mkdir = null,
        .read = &opaque {
            pub fn read(_: *types.Dentry_T) anyerror![]u8 {
               pid0.read = true;
               return @constCast("Hello, World!");
            }
        }.read,
        .write = &opaque {
            pub fn write(_: *types.Dentry_T, _: []const u8) anyerror!void {
               pid0.write = true;
            }
        }.write,
        .unlink = null,
        .chmod = null,
        .chown = null,
    },
    .child = null,
    .parent = null,
    .younger_brother = null,
    .older_brother = null,
    .private = null,
};

var nvme_dentry: types.Dentry_T = .{
    .d_name = "nvme",
    .d_inode = &block_inode,
    .d_sblock = null,
    .d_private = null,
    .d_op = &types.InodeOp_T {
        .lookup = null,
        .create = null,
        .iterator = null,
        .mkdir = null,
        .read = &opaque {
            pub fn read(_: *types.Dentry_T) anyerror![]u8 {
               nvme.read = true;
               return @constCast("Hello, World!");
            }
        }.read,
        .write = &opaque {
            pub fn write(_: *types.Dentry_T, _: []const u8) anyerror!void {
               nvme.write = true;
            }
        }.write,
        .unlink = null,
        .chmod = null,
        .chown = null,
    },
    .child = null,
    .parent = null,
    .younger_brother = null,
    .older_brother = null,
    .private = null,
};

var sblock: types.Superblock_T = .{
    .root_inode = &dir_inode,
    .block_size = 10,
    .data_block_start = 10,
    .inode_table_start = 10,
    .magic = 10,
    .private_data = null,
    .total_blocks = 10,
    .total_inodes = 10,
    .inode_op = &types.InodeOp_T {
        .lookup = &opaque {
            pub fn lookup(_: *types.Dentry_T, name: []const u8) anyerror!*types.Dentry_T {
                if(name[0] == 'p') return &proc_dentry;
                if(name[0] == 'd') return &dev_dentry;
                return types.VfsErr_T.NoNFound;
            }
        }.lookup,
        .create = null,
        .iterator = null,
        .mkdir = null,
        .read = null,
        .write = null,
        .unlink = null,
        .chmod = null,
        .chown = null,
    },
    .fs = {},
};

var dir_inode: types.Inode_T = .{
    .data_block = 10,
    .gid = 10,
    .inode = 10,
    .mode = .{
        .owner = .{
            .r = 1,
            .w = 1,
            .x = 1,
        },
        .group = .{
            .r = 1,
            .w = 1,
            .x = 1,
        },
        .other = .{
            .r = 1,
            .w = 1,
            .x = 1,
        },
    },
    .nlinks = 10,
    .type = .directory,
    .uid = 10,
    .data_inode = 0,
};

var block_inode: types.Inode_T = .{
    .data_block = 10,
    .gid = 10,
    .inode = 10,
    .mode = .{
        .owner = .{
            .r = 1,
            .w = 1,
            .x = 1,
        },
        .group = .{
            .r = 1,
            .w = 1,
            .x = 1,
        },
        .other = .{
            .r = 1,
            .w = 1,
            .x = 1,
        },
    },
    .nlinks = 10,
    .type = .block,
    .uid = 10,
    .data_inode = 0,
};

test "VFS Tree" {
    const root_branch = try aux.resolve_path("/", null, &main.root);
    root_branch.d_sblock = &sblock;
    root_branch.d_op = sblock.inode_op;
    try main.create("/dev/", "sba", null, 0, 0, .{
        .owner = .{ .r = 1, .w = 1, .x = 1, },
        .group = .{ .r = 1, .w = 1, .x = 1, },
        .other = .{ .r = 1, .w = 1, .x = 1, },
    });
    _ = try aux.resolve_path("/dev/sba", null, &main.root);
    try main.create("/proc/", "self", null, 0, 0, .{
        .owner = .{ .r = 1, .w = 1, .x = 1, },
        .group = .{ .r = 1, .w = 1, .x = 1, },
        .other = .{ .r = 1, .w = 1, .x = 1, },
    });
    _ = try aux.resolve_path("/proc/self", null, &main.root);
    try main.create("/dev/", "nvme", null, 0, 0, .{
        .owner = .{ .r = 1, .w = 1, .x = 1, },
        .group = .{ .r = 1, .w = 1, .x = 1, },
        .other = .{ .r = 1, .w = 1, .x = 1, },
    });
    _ = try aux.resolve_path("/dev/nvme", null, &main.root);
    try main.create("/proc/", "0", null, 0, 0, .{
        .owner = .{ .r = 1, .w = 1, .x = 1, },
        .group = .{ .r = 1, .w = 1, .x = 1, },
        .other = .{ .r = 1, .w = 1, .x = 1, },
    });
    try main.write("/dev/sba", null, "Hello, World!");
    try main.write("/proc/self", null, "Hello, World!");
    try main.write("/proc/0", null, "Hello, World!");
    try main.write("/dev/nvme", null, "Hello, World!");
    _ = try main.read("/dev/sba", null);
    _ = try main.read("/proc/self", null);
    _ = try main.read("/proc/0", null);
    _ = try main.read("/dev/nvme", null);
    if(main.write("/dev/", null, "Hello, World!")) |_| return error.WriteInDirectory else |err| { if(err != types.VfsErr_T.InvalidOperation) return err; }
    if(main.write("/proc/", null, "Hello, World!")) |_| return error.WriteInDirectory else |err| { if(err != types.VfsErr_T.InvalidOperation) return err; }
    if(main.read("/dev/", null)) |_| { return error.ReadInDirectory; } else |err| { if(err != types.VfsErr_T.InvalidOperation) return err; }
    if(main.read("/proc/", null)) |_| { return error.ReadInDirectory; } else |err| { if(err != types.VfsErr_T.InvalidOperation) return err; }
    for(all_call) |call| {
        if(!call.read) return error.FailedToCallRead;
        if(!call.write) return error.FailedToCallWrite;
    }
}
