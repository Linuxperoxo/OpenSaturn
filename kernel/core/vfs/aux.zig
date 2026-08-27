// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const lib: type = @import("root").lib;
const main: type = @import("main.zig");

const allocator: type = @import("allocator.zig");
const mem: type = lib.kernel.mem;
const fmt: type = lib.kernel.fmt;

const Inode: type = types.Inode;
const InodeOp: type = types.InodeOp;
const SuperBlock: type = types.Superblock;
const Dentry: type = types.Dentry;
const VfsErr: type = types.VfsErr;
const Op: type = enum {
    read,
    write,
    exec,
    unlink,
    create,
    mkdir,
    chmod,
    chown,
};

pub noinline fn resolvePath(path: []const u8, root: *Dentry) VfsErr!*Dentry {
    const dentries = fmt.splitAlloc(path, '/', &allocator.sba.allocator)
    catch |err| switch(err) {
        error.WithoutSub => return root,
        else => return VfsErr.PathResolveError,
    };
    defer {
        allocator.sba.allocator.free(dentries) catch {
            @branchHint(.unlikely);
            // klog()
        };
    }
    if(root.d_sblock == null) return VfsErr.NoNFound;
    if(root.child == null) {
        root.child = root.d_sblock.?.inode_op.lookup.?(root, dentries[0]) catch
            return VfsErr.NoNFound;
        root.child.?.parent = root;
        root.child.?.younger_brother = null;
        root.child.?.older_brother = null;
        root.child.?.child = null;
    }
    var current_dentry: *Dentry = root.child.?;
    for(dentries, 0..) |dentry, i| {
        sw: switch((enum { step0, step1 }).step0) {
            .step0 => {
                @branchHint(.likely);
                var next: ?*Dentry = current_dentry;
                while(next != null) : (next = next.?.younger_brother) {
                    if(mem.eql(next.?.d_name, dentry, .{ .case = true })) {
                        @branchHint(.cold);
                        if(i + 1 >= dentries.len) return next.?;
                        if(next.?.child == null) {
                            @branchHint(.cold);
                            next.?.child = next.?.d_op.?.lookup.?(next.?, dentries[i + 1]) catch
                                return VfsErr.NoNFound;
                            next.?.child.?.parent = next;
                        }
                        if(next.?.d_inode.?.type != .directory) return VfsErr.NoNFound;
                        current_dentry = next.?.child.?;
                        break :sw {};
                    }
                }
                continue :sw .step1;
            },
            .step1 => {
                @branchHint(.unlikely);
                current_dentry.younger_brother = current_dentry.parent.?.d_op.?.lookup.?(current_dentry.parent.?, dentry) catch
                    return VfsErr.NoNFound;
                current_dentry.younger_brother.?.parent = current_dentry.parent;
                current_dentry.younger_brother.?.older_brother = current_dentry;
                current_dentry.younger_brother.?.younger_brother = null;
                current_dentry.younger_brother.?.child = null;
                current_dentry = current_dentry.younger_brother.?;
                continue :sw .step0;
            },
        }
    }
    return current_dentry;
}

pub inline fn permDecode(dentry: *Dentry, gid: []const types.Gid, uid: types.Uid) types.Perm {
    if(dentry.d_inode.?.uid == uid)
        return dentry.d_inode.?.mode.owner;
    for(dentry.d_inode.?.gid) |inode_gid|
        if(inode_gid == gid)
            return dentry.d_inode.?.mode.group;
    return dentry.d_inode.?.mode.other;
}

pub inline fn isValidOp(dentry: *Dentry, op: Op) VfsErr!void {
    const file_type: types.FileType = r: {
        if(dentry == &main.root) break :r .directory;
        if(dentry.d_inode == null or dentry.d_op == null) return VfsErr.InvalidDentry;
        break :r dentry.d_inode.?.type;
    };
    switch(file_type) {
        .block, .char, .regular => {
            return switch(op) {
                .read => if(dentry.d_op.?.read == null) VfsErr.InvalidOperation,
                .write => if(dentry.d_op.?.write == null) VfsErr.InvalidOperation,
                .unlink => if(dentry.d_op.?.unlink == null) VfsErr.InvalidOperation,
                .chmod => if(dentry.d_op.?.chmod == null) VfsErr.InvalidOperation,
                .chown => if(dentry.d_op.?.chown == null) VfsErr.InvalidOperation,
                .exec => unreachable, // TODO:
                else => VfsErr.InvalidOperation,
            };
        },
        .directory, .link => {
            return switch(op) {
                .unlink => if(dentry.d_op.?.unlink == null) VfsErr.InvalidOperation,
                .create => if(dentry.d_op.?.create == null) VfsErr.InvalidOperation,
                .mkdir => if(dentry.d_op.?.mkdir == null) VfsErr.InvalidOperation,
                .chmod => if(dentry.d_op.?.chmod == null) VfsErr.InvalidOperation,
                .chown => if(dentry.d_op.?.chown == null) VfsErr.InvalidOperation,
                else => VfsErr.InvalidOperation,
            };
        },
    }
}
