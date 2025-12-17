// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const c: type = @import("root").kernel.utils.c;
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
const uid_T: type = types.uid_T;
const gid_T: type = types.gid_T;
const mode_T: type = types.mode_T;

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
    fs_name: []const u8,
) VfsErr_T!void {
    const dentry_mount: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{
        path, current, &root
    });
    if(dentry_mount.d_sblock != null) return VfsErr_T.AlreadyMounted;
    const fs_struct: *fs.Fs_T = @constCast(fs.search_fs(fs_name) catch return VfsErr_T.FilesystemMountError);
    if(c.c_bool(fs_struct.flags.control.nomount)) {
        fs_struct.flags.internal.fault.mount = 1;
        return;
    }
    const sblock = fs_struct.mount() catch {
        fs_struct.flags.internal.fault.mount = 1;
        return VfsErr_T.FilesystemMountError;
    };
    dentry_mount.d_sblock = sblock;
    dentry_mount.d_op = sblock.inode_op;
    fs_struct.flags.internal.mounted = 1;
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

// preferi deixar create/mkdir e chmod/chown em funcoes diferentes por mais que a logica
// seja exatamente a mesma, isso facilita achar problemas

pub fn create(
    parent: []const u8,
    name: []const u8,
    current: ?*Dentry_T,
    uid: uid_T,
    gid: gid_T,
    mode: mode_T,
) VfsErr_T!void {
    const dentry_parent: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{ 
        parent, current, &root
    });
    try aux.is_valid_op(dentry_parent, .create);
    dentry_parent.d_op.?.create.?(dentry_parent, name, uid, gid, mode) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

pub fn mkdir(
    parent: []const u8,
    name: []const u8,
    current: ?*Dentry_T,
    uid: uid_T,
    gid: gid_T,
    mode: mode_T,
) VfsErr_T!void {
    const dentry_parent: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{ 
        parent, current, &root
    });
    try aux.is_valid_op(dentry_parent, .mkdir);
    return dentry_parent.d_op.?.mkdir.?(dentry_parent, name, uid, gid, mode) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

pub fn chmod(
    path: []const u8,
    current: ?*Dentry_T,
    mode: mode_T,
) VfsErr_T!void {
    const dentry_chmod: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{
        path, current, &root
    });
    try aux.is_valid_op(dentry_chmod, .chmod);
    dentry_chmod.d_op.?.chmod(dentry_chmod, mode) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

pub fn chown(
    path: []const u8,
    current: ?*Dentry_T,
    uid: uid_T,
    gid: gid_T,
) VfsErr_T!void {
    const dentry_chown: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{
        path, current, &root
    });
    try aux.is_valid_op(dentry_chown, .chown);
    dentry_chown.d_op.?.chmod(dentry_chown, uid, gid) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

pub fn read(path: []const u8, current: ?*Dentry_T) VfsErr_T![]u8 {
    const dentry_read: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{
        path, current, &root
    });
    try aux.is_valid_op(dentry_read, .read);
    return @call(.never_inline, dentry_read.d_op.?.read.?, .{ dentry_read }) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

pub fn write(path: []const u8, current: ?*Dentry_T, src: []const u8) VfsErr_T!void {
    const dentry_write: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{
        path, current, &root
    });
    try aux.is_valid_op(dentry_write, .write);
    @call(.never_inline,dentry_write.d_op.?.write.?, .{ dentry_write, src }) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

pub fn unlink(path: []const u8, current: ?*Dentry_T) VfsErr_T!void {
    const dentry_unlink: *Dentry_T = try @call(.never_inline, aux.resolve_path, .{
        path, current, &root
    });
    try aux.is_valid_op(dentry_unlink, .unlink);
    // removemos dentry da arvore vfs, isso evita acharmos um dentry que nao existe mais
    // no fs, mas existe na arvore vfs
    if(dentry_unlink.older_brother == null) {
        dentry_unlink.parent.?.child = dentry_unlink.younger_brother;
    } else {
        dentry_unlink.older_brother.?.younger_brother = dentry_unlink.younger_brother;
        if(dentry_unlink.younger_brother != null) {
            dentry_unlink.younger_brother.?.older_brother = dentry_unlink.older_brother;
        }
    }
    @call(.never_inline,dentry_unlink.d_op.?.unlink.?, .{ dentry_unlink }) catch {
        // klog()
        return VfsErr_T.OperationFailed;
    };
}

pub fn touch(path: []const u8, current: ?*Dentry_T) VfsErr_T!void {
    _ = try @call(.never_inline, aux.resolve_path, .{
        path, current, &root
    });
}
