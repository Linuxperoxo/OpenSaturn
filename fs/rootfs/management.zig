// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

// VFS
const Dentry_T: type = @import("root").core.vfs.interfaces.Dentry_T;
const Superblock_T: type = @import("root").core.vfs.interfaces.Superblock_T;
const FileType_T: type = @import("root").core.vfs.interfaces.FileType_T;
const InodeOp_T: type = @import("root").core.vfs.interfaces.InodeOp_T;
const Inode_T: type = @import("root").core.vfs.interfaces.Inode_T;
const VfsErr_T: type = @import("root").core.vfs.interfaces.VfsErr_T;

// rootfs
const RootfsBranch_T: type = @import("rootfs.zig").RootfsBranch_T;
const RootfsErr_T: type = @import("rootfs.zig").RootfsErr_T;
const DefaultDirs = [_]*RootfsBranch_T {
    @import("rootfs.zig").@"/",
    @import("rootfs.zig").@"usr",
    @import("rootfs.zig").@"sys",
    @import("rootfs.zig").@"dev",
    @import("rootfs.zig").@"volatile",
};
const rootfsSuperblock: *Superblock_T = @import("rootfs.zig").rootfsSuperblock;

comptime {
    for(DefaultDirs) |e| {
        e.dentry.inode.?.ops = &InodeOp_T {
            .create = rootfs_create,
            .interator = rootfs_interator,
            .lookup = rootfs_lookup,
            .mkdir = rootfs_mkdir,
            .unlink = rootfs_unlink,
        };
    }
}

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

pub fn rootfs_mount() RootfsErr_T!*Superblock_T {
    return rootfsSuperblock;
}

pub fn rootfs_umount() void {
    // Como e um sistema de arquivos em ram, devemos
    // liberar qualquer memoria aqui
}

fn rootfs_lookup(
    parent: *Dentry_T,
    name: []const u8
) RootfsErr_T!*Dentry_T {
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
) RootfsErr_T!*Dentry_T {
    
}

fn rootfs_create(
    parent: *Dentry_T,
    name: []const u8,
    uid: u16,
    gid: u32,
    mode: u16,
) RootfsErr_T!*Dentry_T {
    
}

fn rootfs_unlink(
    parent: *Dentry_T,
    name: []const u8,
) RootfsErr_T!void {
    
}

fn rootfs_interator(
    parent: *Dentry_T
) []const *Dentry_T {
    
}

