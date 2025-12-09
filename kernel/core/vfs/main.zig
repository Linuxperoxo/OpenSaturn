// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const fs: type = @import("root").core.fs;
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");

const Inode_T: type = types.Inode_T;
const InodeOp_T: type = types.InodeOp_T;
const SuperBlock_T: type = types.Superblock_T;
const Dentry_T: type = types.Dentry_T;
const VfsErr_T: type = types.VfsErr_T;

pub var root: Dentry_T = .{
    .d_name = "/",
    .d_inode = null,
    .d_sblock = null,
    .d_op = null,
    .d_private = null,
    .child = null,
    .younger_brother = null,
    .older_brother = null,
    .parent = null,
    .private = null,
};

// TODO: por enquanto nao vamos fazer isso, mas quando tivermos
// userspace, para cada operacao do vfs, precisamos verificar
// as permissoes

pub fn mount(
    path: []const u8,
    current: ?*Dentry_T,
    fs_struct: if(!builtin.is_test) *const fs.interfaces.Fs_T else void
) VfsErr_T!void {
    const dentry_mount: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{ 
        path, current, &root
    });
    if(dentry_mount.d_sblock != null) return VfsErr_T.AlreadyMounted;
    if(builtin.is_test) return; // for test
    const sblock = fs_struct.mount() catch return VfsErr_T.FilesystemMountError;
    dentry_mount.d_sblock = sblock;
    dentry_mount.d_op = sblock.inode_op;
}

pub fn umount(path: []const u8, current: ?*Dentry_T) VfsErr_T!void {
    const dentry_umount: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{ 
        path, current, &root
    });
    if(dentry_umount.d_sblock == null) return VfsErr_T.NothingToUmount;
    @call(.never_inline, dentry_umount.d_sblock.?.fs.unmount, .{});
    dentry_umount.child = null;
    dentry_umount.d_sblock = null;
    dentry_umount.d_op = dentry_umount.parent.?.d_op;
}

// NOTE: apenas quando tivermos task
//pub fn open(path: []const u8, current: ?*Dentry_T) VfsErr_T!*Dentry_T {}

pub fn read(path: []const u8, current: ?*Dentry_T) VfsErr_T![]u8 {
    const dentry_read: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{ 
        path, current, &root
    });
    try aux.cmp_op(dentry_read, .read);
    return @call(.never_inline, dentry_read.d_op.?.read.?, .{}) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

pub fn write(path: []const u8, current: ?*Dentry_T, src: []const u8) VfsErr_T!void {
    const dentry_write: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{ 
        path, current, &root
    });
    try aux.cmp_op(dentry_write, .write);
    @call(.never_inline,dentry_write.d_op.?.write.?, .{ src }) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

pub fn unlink(path: []const u8, current: ?*Dentry_T) VfsErr_T!void {
    const dentry_unlink: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{ 
        path, current, &root
    });
    try aux.cmp_op(dentry_unlink, .unlink);
    @call(.never_inline,dentry_unlink.d_op.?.unlink, .{
        dentry_unlink.parent.?, dentry_unlink.d_name
    }) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

