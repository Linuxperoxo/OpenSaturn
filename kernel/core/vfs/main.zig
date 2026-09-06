// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const c: type = @import("root").lib.kernel.c;
const builtin: type = @import("builtin");
const fs: type = @import("root").core.fs;
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");
const fmt: type = @import("root").lib.kernel.fmt;

const Fs: type = fs.Fs;
const Inode: type = types.Inode;
const InodeOp: type = types.InodeOp;
const Superblock: type = types.Superblock;
const Dentry: type = types.Dentry;
const VfsErr: type = types.VfsErr;
const Uid: type = types.Uid;
const Gid: type = types.Gid;
const Mode: type = types.Mode;

pub var root: Dentry = .{
    .d_name = "/",
    .d_inode = null,
    .d_sblock = null,
    .d_op = null,
    .d_private = null,
    .child = null,
    .younger_brother = null,
    .older_brother = null,
    .parent = null,
};

// TODO: por enquanto nao vamos fazer isso, mas quando tivermos
// userspace, para cada operacao do vfs, precisamos verificar
// as permissoes

// TODO: armazenar informacoes de todas as montagens

pub fn mount(src: []const u8, path: []const u8, fs_name: []const u8) VfsErr!void {
    const dentry_mount: *Dentry = try aux.resolvePath(path, &root);

    if(dentry_mount.d_sblock != null)
        return VfsErr.AlreadyMounted;

    const fs_struct: *Fs = fs.schfs(fs_name)
        catch return VfsErr.NoNFound;

    const sblock: *const Superblock = fs_struct.mount(src)
        catch return VfsErr.FilesystemMountError;

    dentry_mount.d_sblock = @constCast(sblock);
    dentry_mount.d_op = sblock.inode_op;
}

pub fn umount(path: []const u8) VfsErr!void {
    const dentry_umount: *Dentry = try aux.resolvePath(path, &root);

    if(dentry_umount.d_sblock == null)
        return VfsErr.NothingToUmount;

    @call(.never_inline, dentry_umount.d_sblock.?.fs.umount, .{});

    dentry_umount.child = null;
    dentry_umount.d_sblock = null;
    dentry_umount.d_op = dentry_umount.parent.?.d_op;
}

// NOTE: apenas quando tivermos task
//pub fn open(path: []const u8, current: ?*Dentry) VfsErr!*Dentry {}

// preferi deixar create/mkdir e chmod/chown em funcoes diferentes por mais que a logica
// seja exatamente a mesma, isso facilita achar problemas

pub noinline fn create(
    parent: []const u8,
    name: []const u8,
    uid: Uid,
    gid: Gid,
    mode: Mode,
) VfsErr!void {
    const dentry_parent: *Dentry = aux.resolvePath(parent, &root)
        catch return types.VfsErr.WithoutParent;

    try aux.isValidOp(dentry_parent, .create);

    dentry_parent.d_op.?.create.?(dentry_parent, name, uid, gid, mode) catch {
        // klog()
        return VfsErr.OperationFailed;
    };
}

pub noinline fn mkdir(
    parent: []const u8,
    name: []const u8,
    uid: Uid,
    gid: Gid,
    mode: Mode,
) VfsErr!void {
    const dentry_parent: *Dentry = aux.resolvePath(parent, &root)
        catch return types.VfsErr.WithoutParent;

    try aux.isValidOp(dentry_parent, .mkdir);

    return dentry_parent.d_op.?.mkdir.?(dentry_parent, name, uid, gid, mode) catch {
        // klog()
        return VfsErr.OperationFailed;
    };
}

pub noinline fn chmod(path: []const u8, mode: Mode,) VfsErr!void {
    const dentry_chmod: *Dentry = try aux.resolvePath(path, &root);

    try aux.isValidOp(dentry_chmod, .chmod);

    dentry_chmod.d_op.?.chmod(dentry_chmod, mode) catch {
        // klog()
        return VfsErr.OperationFailed;
    };
}

pub noinline fn chown(
    path: []const u8,
    uid: Uid,
    gid: Gid,
) VfsErr!void {
    const dentry_chown: *Dentry = try aux.resolvePath(path, &root);

    try aux.isValidOp(dentry_chown, .chown);

    dentry_chown.d_op.?.chmod(dentry_chown, uid, gid) catch {
        // klog()
        return VfsErr.OperationFailed;
    };
}

pub noinline fn read(path: []const u8, offset: usize) VfsErr![]u8 {
    const dentry_read: *Dentry = try aux.resolvePath(path, &root);

    try aux.isValidOp(dentry_read, .read);

    return @call(.never_inline, dentry_read.d_op.?.read.?, .{ dentry_read, offset }) catch {
        // klog()
        return VfsErr.OperationFailed;
    };
}

pub noinline fn write(path: []const u8, src: []const u8, offset: usize) VfsErr!void {
    const dentry_write: *Dentry = try aux.resolvePath(path, &root);

    try aux.isValidOp(dentry_write, .write);

    @call(.never_inline,dentry_write.d_op.?.write.?, .{ dentry_write, src, offset }) catch {
        // klog()
        return VfsErr.OperationFailed;
    };
}

pub noinline fn unlink(path: []const u8) VfsErr!void {
    const dentry_unlink: *Dentry = try aux.resolvePath(path, &root);

    try aux.isValidOp(dentry_unlink, .unlink);

    // removemos dentry da arvore vfs, isso evita acharmos um dentry que nao existe mais
    // no fs, mas existe na arvore vfs
    if(dentry_unlink.older_brother == null) {
        dentry_unlink.parent.?.child = dentry_unlink.younger_brother;
    } else {
        dentry_unlink.older_brother.?.younger_brother = dentry_unlink.younger_brother;

        if(dentry_unlink.younger_brother != null)
            dentry_unlink.younger_brother.?.older_brother = dentry_unlink.older_brother;
    }

    @call(.never_inline,dentry_unlink.d_op.?.unlink.?, .{ dentry_unlink }) catch {
        // klog()
        return VfsErr.OperationFailed;
    };
}

pub noinline fn touch(path: []const u8) VfsErr!void {
    _ = try aux.resolvePath(path, &root);
}
