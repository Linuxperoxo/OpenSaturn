// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

// kernel vfs types
const Dentry_T: type = @import("root").core.vfs.interfaces.Dentry_T;
const Superblock_T: type = @import("root").core.vfs.interfaces.Superblock_T;
const FileType_T: type = @import("root").core.vfs.interfaces.FileType_T;
const InodeOp_T: type = @import("root").core.vfs.interfaces.InodeOp_T;
const Inode_T: type = @import("root").core.vfs.interfaces.Inode_T;
const VfsErr_T: type = @import("root").core.vfs.interfaces.VfsErr_T;

// kernel fs types
const FsErr_T: type = @import("root").interfaces.fs.FsErr_T;

// rootfs
const RootfsBranch_T: type = @import("rootfs.zig").RootfsBranch_T;
const RootfsErr_T: type = @import("rootfs.zig").RootfsErr_T;
const defaultDirs: [5]RootfsBranch_T = .{
    @import("files.zig").@"/",
    @import("files.zig").@"usr",
    @import("files.zig").@"dev",
    @import("files.zig").@"sys",
    @import("files.zig").@"volatile",
};
const rootfsSuperblock: *Superblock_T = @constCast(&Superblock_T {
    .magic = 0x703,
    .block_size = 0,
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_table_start = 0,
    .data_block_start = 0,
    .root_inode = defaultDirs[0].dentry.inode,
    .private_data = defaultDirs[0],
});

fn cmp_name(
    noalias s0: []const u8,
    noalias s1: []const u8
) bool {
    if(s0.len != s1.len) {
        return false;
    }
    for(0..s0.len) |i| {
        if(s0[i] != s1[i]) {
            return false;
        }
    }
    return true;
}

pub fn rootfs_mount() FsErr_T!Superblock_T {
    return FsErr_T.AllocInternal;
}

pub fn rootfs_unmount() FsErr_T!void {
    // Como e um sistema de arquivos em ram, devemos
    // liberar qualquer memoria aqui
}

fn rootfs_lookup(
    parent: *Dentry_T,
    name: []const u8
) anyerror!*Dentry_T {
    var current: ?*RootfsBranch_T = block0: {
        if(parent.inode) |NoNNullInode| {
            break :block0 NoNNullInode.private;
        }
        break :block0 null;
    };
    while(current) |NoNNullCurrent| {
        if(@call(.always_inline, &cmp_name, .{
            NoNNullCurrent.dentry.name,
            name
        })) {
            return NoNNullCurrent.dentry;
        }
        current = NoNNullCurrent.brother;
    }
    return RootfsErr_T.NonFound;
}

fn rootfs_mkdir(
    parent: *Dentry_T,
    name: []const u8,
    uid: u16,
    gid: u32,
    mode: u16,
) anyerror!*Dentry_T {
    _ = parent;
    _ = name;
    _ = uid;
    _ = gid;
    _ = mode;
    return RootfsErr_T.NonFound;
}

fn rootfs_create(
    parent: *Dentry_T,
    name: []const u8,
    uid: u16,
    gid: u32,
    mode: u16,
) anyerror!*Dentry_T {
    _ = parent;
    _ = name;
    _ = uid;
    _ = gid;
    _ = mode;
    return RootfsErr_T.NonFound;
}

fn rootfs_unlink(
    parent: *Dentry_T,
    name: []const u8,
) anyerror!void {
    _ = parent;
    _ = name;
}

fn rootfs_interator(
    parent: *Dentry_T
) []const *Dentry_T {
    _ = parent;
}

