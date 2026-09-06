// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: inode.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").interfaces.vfs;

current: usize = 0,

pub inline fn inodeGen(
    self: *@This(),
    allocator: anytype,
    itype: vfs.FileType,
    uid: vfs.Uid,
    gid: vfs.Gid,
    mode: vfs.Mode,
) anyerror!*vfs.Inode {
    const inode: *vfs.Inode = &(try allocator.alloc(vfs.Inode, 1))[0];
    inode.* = .{
        .inode = self.current,
        .type = itype,
        .uid = uid,
        .gid = gid,
        .mode = mode,
        .nlinks = 0,
        .data_block = @intFromPtr(&inode),
        .data_inode = 0,
    };
    self.current += 1;
    return inode;
}
