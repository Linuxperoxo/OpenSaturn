// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const rootfs: type = @import("rootfs.zig");
const types: type = @import("types.zig");
const mem: type = @import("root").kernel.utils.mem;
const c: type = @import("root").kernel.utils.c;
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");
// required
const inode_utils: type = rootfs.__SaturnModuleDescription__.request_lib("inode-utils").?;

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

const dir_inode_ops: InodeOp_T = .{
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
    .private_data = &types.list_T {},
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_op = &dir_inode_ops,
};

var inode: inode_utils = .{
    .current = 0,
};

pub fn rootfs_mount() anyerror!*const Superblock_T {
    return &superblock;
}

pub fn rootfs_umount() FsErr_T!void {
    // rootfs nunca deve ser desmontado
    unreachable;
}

pub fn chmod(dentry: *Dentry_T, mode: mode_T) anyerror!void {
    @constCast(dentry.d_inode.?).mode = mode;
}

pub fn chown(dentry: *Dentry_T, uid: uid_T, gid: gid_T) anyerror!void {
    @constCast(dentry.d_inode.?).uid = uid;
    @constCast(dentry.d_inode.?).gid = gid;
}

pub fn lookup(parent: *Dentry_T, name: []const u8) anyerror!*Dentry_T {
    const list_ptr: ?*list_T = aux.obtain_rootfs_d(parent).list;
    if(list_ptr == null or !list_ptr.?.is_initialized()) return RootfsErr_T.NonFound;
    const param: struct { cmp: []const u8 } = .{
        .cmp = name,
    };
    return (list_ptr.?.iterator_handler(
        param,
        &opaque {
            pub fn handler(rootfs_dentry: *RootfsDentry_T, rep: @TypeOf(param)) anyerror!void {
                if(!mem.eql(rootfs_dentry.dentry.d_name, rep.cmp, .{ .case = true }))
                    return error.Continue;
            }
        }.handler,
    ) catch |err| return switch(err) {
        listErr_T.EndOfIterator => RootfsErr_T.NonFound,
        else => r: {
            // klog()
            break :r RootfsErr_T.IteratorInternalError;
        },
    }).dentry;
}

pub fn mkdir(parent: *Dentry_T, name: []const u8, uid: uid_T, gid: gid_T, mode: mode_T) anyerror!void {
    // FIXME: fault: caso seja o bloco montado, devemos pegar diretamente o private_data,
    // que ja e um ponteiro para uma lista de *RootfsDentry_T
    const parent_rootfs_entry: *RootfsDentry_T = aux.obtain_rootfs_d(parent);
    asm volatile(
        \\ jmp .
        \\ jmp 0xAA00
        :
        :[_] "{eax}" (parent_rootfs_entry)
    );
    parent_rootfs_entry.list = if(parent_rootfs_entry.list != null) parent_rootfs_entry.list else r: {
        if(allocator.sba.alloc_one(list_T)) |list| {
            list.private = null;
            break :r list;
        } else |err| {
            return err;
        }
    };
    if(!parent_rootfs_entry.list.?.is_initialized()) parent_rootfs_entry.list.?.init(&allocator.sba.allocator) catch {
        // klog()
        return RootfsErr_T.ListInitFailed;
    };
    const rootfs_entry: *RootfsDentry_T = try aux.alloc_init_entry();
    rootfs_entry.dentry.d_inode = inode.inode_gen(
        &allocator.sba.allocator,
        .directory,
        uid,
        gid,
        mode,
    ) catch {
        // klog()
        allocator.sba.allocator.free(rootfs_entry.dentry) catch {};
        allocator.sba.allocator.free(rootfs_entry) catch {};
        return RootfsErr_T.AllocatorFailed;
    };
    errdefer {
        // klog()
        allocator.sba.allocator.free(@constCast(rootfs_entry.dentry.d_inode.?)) catch {};
        allocator.sba.allocator.free(rootfs_entry.dentry) catch {};
        allocator.sba.allocator.free(rootfs_entry) catch {};
    }
    rootfs_entry.dentry.d_name = try allocator.sba.allocator.alloc(u8, name.len);
    mem.cpy(@constCast(rootfs_entry.dentry.d_name), name);
    errdefer allocator.sba.allocator.free(@constCast(rootfs_entry.dentry.d_name)) catch {};
    try parent_rootfs_entry.list.?.push_in_list(&allocator.sba.allocator, rootfs_entry);
}

pub fn unlink(_: *Dentry_T) anyerror!void {

}
