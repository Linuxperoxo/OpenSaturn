// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").core.fs;
const types: type = @import("types.zig");

const Inode_T: type = types.Inode_T;
const InodeOp_T: type = types.InodeOp_T;
const Dentry_T: type = types.InodeOp_T;
const SuperBlock_T: type = types.Superblock_T;
const TreeBranch_T: type = types.TreeBranch_T;
const VfsErr_T: type = types.VfsErr_T;

var root: TreeBranch_T = .{
    .sblock = null,
    .fs = null,
    .child = null,
    .parent = &root,
    .brother = null,
    .flags = .{
        .init = 0,
    },
};

pub fn mount(
    current: ?[]const u8,
    path: []const u8,
    fs_struct: *const fs.interfaces.Fs_T
) VfsErr_T!void {
    if(path.len == 0 
        or current == null and path[0] != '0') return VfsErr_T. 
}

pub fn umount(path: []const u8) VfsErr_T!void {

}


