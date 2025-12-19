// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: inode.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").interfaces.vfs;

current: usize = 0,

pub inline fn inode_gen(
    self: *@This(),
    allocator: anytype,
    itype: vfs.FileType_T,
    uid: vfs.uid_T,
    gid: vfs.gid_T,
    mode: vfs.mode_T,
) anyerror!*vfs.Inode_T {
    const inode: *vfs.Inode_T = &(try allocator.alloc(vfs.Inode_T, 1))[0];
    inode.* = .{
        .inode = self.current,
        .type = itype,
        .uid = uid,
        .gid = gid,
        .mode = mode,
        .nlinks = 0,
        .data_block = 0,
        .data_inode = 0,
    };
    self.current += 1;
    return inode;
}
