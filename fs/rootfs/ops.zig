// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ops.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const rootfs: type = @import("rootfs.zig");
const types: type = @import("types.zig");
const mem: type = @import("root").lib.utils.mem;
const c: type = @import("root").lib.utils.c;
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");

const Dentry_T: type = interfaces.vfs.Dentry_T;
const Superblock_T: type = interfaces.vfs.Superblock_T;
const FileType_T: type = interfaces.vfs.FileType_T;
const InodeOp_T: type = interfaces.vfs.InodeOp_T;
const Inode_T: type = interfaces.vfs.Inode_T;
const VfsErr_T: type = interfaces.vfs.VfsErr_T;
const Fs_T: type = interfaces.fs.Fs_T;
const FsErr_T: type = interfaces.fs.FsErr_T;
const uid_T: type = interfaces.vfs.uid_T;
const gid_T: type = interfaces.vfs.gid_T;
const mode_T: type = interfaces.vfs.mode_T;
const RootfsDentry_T: type = types.RootfsDentry_T;
const RootfsErr_T: type = types.RootfsErr_T;
const list_T: type = types.list_T;
const listErr_T: type = types.listErr_T;
const RootfsPrivate_T: type = types.RootfsPrivate_T;

pub var dir_inode_ops: InodeOp_T = .{
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

var superblock: Superblock_T = .{
    .fs = @alignCast(@ptrCast(&rootfs.rootfs.private)),
    .block_size = 0,
    .data_block_start = 0,
    .inode_table_start = 0,
    .magic = 0xAB00,
    // tudo bem usar esse @constCast em contexto de kernel. Em userspace,
    // isso e uma armadilha, e vai causar segfault, o compilador colocar
    // &RootfsPrivate_T na section .rodata ja que e conhecido em comptime
    // e implicitamente const
    .private_data = @constCast(&RootfsPrivate_T {
        .parent = null,
        .self = @constCast(&RootfsDentry_T {
            .childs = null,
            .dentry = null,
        }),
    }),
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_op = &dir_inode_ops,
};

pub fn rootfs_mount() anyerror!*const Superblock_T {
    return &superblock;
}

pub fn rootfs_umount()anyerror!void {
    // klog()
    return RootfsErr_T.AttemptUmount;
}

pub fn chmod(dentry: *Dentry_T, mode: mode_T) anyerror!void {
    @constCast(dentry.d_inode.?).mode = mode;
}

pub fn chown(dentry: *Dentry_T, uid: uid_T, gid: gid_T) anyerror!void {
    dentry.d_inode.?.uid = uid;
    dentry.d_inode.?.gid = gid;
}

pub fn lookup(parent: *Dentry_T, name: []const u8) anyerror!*Dentry_T {
    const parent_childs_list = aux.obtain_rootfs_private(parent).self.childs orelse
        return RootfsErr_T.NonFound;
    if(!parent_childs_list.is_initialized()) return RootfsErr_T.NonFound;
    const found: *RootfsDentry_T = parent_childs_list.iterator_handler(
        name,
        &opaque {
            pub fn handler(ite_child: *RootfsDentry_T, child_name: []const u8) anyerror!void {
                if(!mem.eql(ite_child.dentry.?.d_name, child_name, .{ .case = true }))
                    return error.Continue;
            }
        }.handler,
    ) catch |err| return switch(err) {
        listErr_T.EndOfIterator => RootfsErr_T.NonFound,
        else => RootfsErr_T.IteratorInternalError,
    };
    return found.dentry.?;
}

pub fn mkdir(parent: *Dentry_T, name: []const u8, uid: uid_T, gid: gid_T, mode: mode_T) anyerror!void {
    const parent_dentry = aux.obtain_rootfs_private(parent).self;
    parent_dentry.childs = if(parent_dentry.childs != null) parent_dentry.childs else r: {
        const new_childs_list: *list_T = try allocator.sba.alloc_one(list_T);
        errdefer allocator.sba.allocator.free(new_childs_list) catch unreachable;
        try new_childs_list.init(&allocator.sba.allocator);
        break :r new_childs_list;
    };

    const vfs_dentry: *Dentry_T = try allocator.sba.alloc_one(Dentry_T);
    errdefer allocator.sba.allocator.free(vfs_dentry) catch unreachable;

    vfs_dentry.d_name = try aux.alloc_name(name);
    errdefer allocator.sba.allocator.free(@constCast(vfs_dentry.d_name)) catch unreachable;

    vfs_dentry.d_inode = try aux.alloc_inode(uid, gid, mode);
    errdefer allocator.sba.allocator.free(vfs_dentry.d_inode.?) catch unreachable;

    const rootfs_private: *RootfsPrivate_T = try aux.alloc_rootfs_dentry();
    errdefer {
        allocator.sba.allocator.free(rootfs_private.self) catch unreachable;
        allocator.sba.allocator.free(rootfs_private) catch unreachable;
    }

    try parent_dentry.childs.?.push_in_list(
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

pub fn unlink(dentry: *Dentry_T) anyerror!void {
    const rootfs_private: *RootfsPrivate_T = aux.obtain_rootfs_private(dentry);
    if(rootfs_private.self.childs != null and rootfs_private.self.childs.?.how_many_nodes() > 0)
        return RootfsErr_T.DirectoryWithChilds;

    const parent_childs_list: *list_T = rootfs_private.parent.?.childs.?;
    _ = parent_childs_list.iterator_handler(
        dentry,
        &opaque {
            pub fn handler(ite_child: *RootfsDentry_T, child_vfs_dentry: *Dentry_T) anyerror!void {
                if(ite_child.dentry.? != child_vfs_dentry)
                    return error.Continue;
            }
        }.handler,
    ) catch |err| return err;

    try parent_childs_list.drop_on_list(
        (parent_childs_list.iterator_index() catch unreachable) - 1,
        &allocator.sba.allocator,
    );

    allocator.sba.allocator.free(rootfs_private.self.dentry.?.d_inode.?) catch unreachable;
    allocator.sba.allocator.free(@constCast(rootfs_private.self.dentry.?.d_name)) catch unreachable;
    allocator.sba.allocator.free(rootfs_private.self.dentry.?) catch unreachable;
    allocator.sba.allocator.free(rootfs_private.self) catch unreachable;
    allocator.sba.allocator.free(rootfs_private) catch unreachable;
}
