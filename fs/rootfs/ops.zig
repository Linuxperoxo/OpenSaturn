// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ops.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const types: type = @import("types.zig");
const mem: type = @import("root").lib.kernel.mem;
const c: type = @import("root").lib.kernel.c;
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");
const rfs: type = @import("fs.zig");

const Dentry: type = interfaces.vfs.Dentry;
const Superblock: type = interfaces.vfs.Superblock;
const FileType: type = interfaces.vfs.FileType;
const InodeOp: type = interfaces.vfs.InodeOp;
const Inode: type = interfaces.vfs.Inode;
const VfsErr: type = interfaces.vfs.VfsErr;
const Fs: type = interfaces.fs.Fs;
const FsErr: type = interfaces.fs.FsErr;
const Uid: type = interfaces.vfs.Uid;
const Gid: type = interfaces.vfs.Gid;
const Mode: type = interfaces.vfs.Mode;
const RootfsDentry: type = types.RootfsDentry;
const RootfsErr: type = types.RootfsErr;
const List: type = types.List;
const ListErr: type = types.ListErr;
const RootfsPrivate: type = types.RootfsPrivate;

pub var dir_inode_ops: InodeOp = .{
    .chmod = &chmod,
    .chown = &chown,
    .create = null,
    .iterator = null,
    .lookup = &lookup,
    .mkdir = &mkdir,
    .read = null,
    .unlink = &unlink,
    .write = null,
};

var superblock: Superblock = .{
    .fs = &rfs.rootfs,
    .block_size = 0,
    .data_block_start = 0,
    .inode_table_start = 0,
    .magic = 0xAB00,
    // tudo bem usar esse @constCast em contexto de kernel. Em userspace,
    // isso e uma armadilha, e vai causar segfault, o compilador colocar
    // &RootfsPrivate na section .rodata ja que e conhecido em comptime
    // e implicitamente const
    .private_data = @constCast(&RootfsPrivate {
        .parent = null,
        .self = @constCast(&RootfsDentry {
            .childs = null,
            .dentry = null,
        }),
    }),
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_op = &dir_inode_ops,
};

pub fn rootfsMount(_: []const u8) anyerror!*const Superblock {
    return &superblock;
}

pub fn rootfsUmount()anyerror!void {
    // klog()
    return RootfsErr.AttemptUmount;
}

pub fn chmod(dentry: *Dentry, mode: Mode) anyerror!void {
    @constCast(dentry.d_inode.?).mode = mode;
}

pub fn chown(dentry: *Dentry, uid: Uid, gid: Gid) anyerror!void {
    dentry.d_inode.?.uid = uid;
    dentry.d_inode.?.gid = gid;
}

pub fn lookup(parent: *Dentry, name: []const u8) anyerror!*Dentry {
    const parent_childs_list = aux.obtainRootfsPrivate(parent).self.childs orelse
        return RootfsErr.NonFound;
    if(!parent_childs_list.isInitialized()) return RootfsErr.NonFound;
    const found: *RootfsDentry = parent_childs_list.iteratorHandler(
        name,
        &opaque {
            pub fn handler(ite_child: *RootfsDentry, child_name: []const u8) anyerror!void {
                if(!mem.eql(ite_child.dentry.?.d_name, child_name, .{ .case = true }))
                    return error.Continue;
            }
        }.handler,
    ) catch |err| return switch(err) {
        ListErr.EndOfIterator => RootfsErr.NonFound,
        else => RootfsErr.IteratorInternalError,
    };
    return found.dentry.?;
}

pub fn mkdir(parent: *Dentry, name: []const u8, uid: Uid, gid: Gid, mode: Mode) anyerror!void {
    const parent_dentry = aux.obtainRootfsPrivate(parent).self;
    parent_dentry.childs = if(parent_dentry.childs != null) parent_dentry.childs else r: {
        const new_childs_list: *List = try allocator.sba.allocOne(List);
        errdefer allocator.sba.allocator.free(new_childs_list) catch unreachable;
        try new_childs_list.init(&allocator.sba.allocator);
        break :r new_childs_list;
    };

    const vfs_dentry: *Dentry = try allocator.sba.allocOne(Dentry);
    errdefer allocator.sba.allocator.free(vfs_dentry) catch unreachable;

    vfs_dentry.d_name = try aux.allocName(name);
    errdefer allocator.sba.allocator.free(@constCast(vfs_dentry.d_name)) catch unreachable;

    vfs_dentry.d_inode = try aux.allocInode(uid, gid, mode);
    errdefer allocator.sba.allocator.free(vfs_dentry.d_inode.?) catch unreachable;

    const rootfs_private: *RootfsPrivate = try aux.allocRootfsDentry();
    errdefer {
        allocator.sba.allocator.free(rootfs_private.self) catch unreachable;
        allocator.sba.allocator.free(rootfs_private) catch unreachable;
    }

    try parent_dentry.childs.?.pushInList(
        &allocator.sba.allocator,
        rootfs_private.self,
    );

    rootfs_private.parent = parent_dentry;
    rootfs_private.self.dentry = vfs_dentry;
    vfs_dentry.* = .{
        .d_name = vfs_dentry.d_name,
        .d_inode = vfs_dentry.d_inode,
        .d_private = rootfs_private,
        .d_op = &dir_inode_ops,
        .d_sblock = null,
        .child = null,
        .younger_brother = null,
        .older_brother = null,
        .parent = null,
    };
}

pub fn unlink(dentry: *Dentry) anyerror!void {
    const rootfs_private: *RootfsPrivate = aux.obtainRootfsPrivate(dentry);
    if(rootfs_private.self.childs != null and rootfs_private.self.childs.?.howManyNodes() > 0)
        return RootfsErr.DirectoryWithChilds;

    const parent_childs_list: *List = rootfs_private.parent.?.childs.?;
    _ = parent_childs_list.iteratorHandler(
        dentry,
        &opaque {
            pub fn handler(ite_child: *RootfsDentry, child_vfs_dentry: *Dentry) anyerror!void {
                if(ite_child.dentry.? != child_vfs_dentry)
                    return error.Continue;
            }
        }.handler,
    ) catch |err| return err;

    try parent_childs_list.dropOnList(
        (parent_childs_list.iteratorIndex() catch unreachable) - 1,
        &allocator.sba.allocator,
    );

    allocator.sba.allocator.free(rootfs_private.self.dentry.?.d_inode.?) catch unreachable;
    allocator.sba.allocator.free(@constCast(rootfs_private.self.dentry.?.d_name)) catch unreachable;
    allocator.sba.allocator.free(rootfs_private.self.dentry.?) catch unreachable;
    allocator.sba.allocator.free(rootfs_private.self) catch unreachable;
    allocator.sba.allocator.free(rootfs_private) catch unreachable;
}
