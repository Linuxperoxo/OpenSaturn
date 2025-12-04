// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
//const fs: type = @import("root").core.fs;
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const kernel: type = @import("root").kernel;
const mem: type = @import("test/mem.zig");

const Inode_T: type = types.Inode_T;
const InodeOp_T: type = types.InodeOp_T;
const SuperBlock_T: type = types.Superblock_T;
const Dentry_T: type = types.Dentry_T;
const VfsErr_T: type = types.VfsErr_T;

var root: Dentry_T = .{
    .d_name = "/",
    .d_inode = null,
    .d_sblock = null,
    .d_op = null,
    .d_private = null,
    .child = null,
    .brother = null,
    .parent = null,
};

inline fn broken_path(path: []const u8) []const[]const u8 {
    const final_offset, var dentry_count = path_len(path);
    var path_sequence: [dentry_count][]const u8 = undefined;
    var i: usize = 0;
    while(i < final_offset) : (i += 1) {
        @branchHint(.likely);
        if(path[i] == '/') {
            @branchHint(.cold);
            continue;
        }
        var end: usize = i;
        while(path[end] != '/' and end < final_offset) : (end += 1) {
            @branchHint(.likely);
        }
        path_sequence[dentry_count - 1] = path[i..end];
        dentry_count -= 1;
        i = end;
    }
    return path_sequence;
}

inline fn path_len(path: []const u8) struct { usize, usize }{
    var final_offset: usize = path.len;
    while(path[final_offset - 1] == '/') : (final_offset -= 1) {}
    return .{
        final_offset,
        r: {
            var dentry_count: usize = 0;
            for(0..final_offset) |i| {
                if(path[i] == '/') continue;
                dentry_count += 1;
            }
            break :r dentry_count;
        },
    };
}

pub fn resolve_path(path: []const u8, current: ?*Inode_T) VfsErr_T!*Dentry_T {
}

pub fn mount(
    path: []const u8,
    current: ?*Inode_T,
    //fs_struct: *const fs.interfaces.Fs_T
) VfsErr_T!void {
    _ = path;
    _ = current;
    //tree_branch.sblock = fs_struct.mount();
    //tree_branch.inode = tree_branch.sblock.?.root_inode;
}

pub fn umount(_: []const u8) VfsErr_T!void {

}


