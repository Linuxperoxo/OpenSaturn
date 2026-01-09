// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const types: type = @import("types.zig");
const lib: type = @import("root").lib;
const main: type = @import("main.zig");

const allocator: type = if(!builtin.is_test) @import("allocator.zig") else
    @import("test/allocator.zig");
const mem: type = if(!builtin.is_test) lib.utils.mem else
    @import("test/mem.zig");
const fmt: type = if(!builtin.is_test) lib.utils.fmt else
    @import("test/fmt.zig");

const Inode_T: type = types.Inode_T;
const InodeOp_T: type = types.InodeOp_T;
const SuperBlock_T: type = types.Superblock_T;
const Dentry_T: type = types.Dentry_T;
const VfsErr_T: type = types.VfsErr_T;
const Op_T: type = enum {
    read,
    write,
    exec,
    unlink,
    create,
    mkdir,
    chmod,
    chown,
};

pub fn resolve_path(path: []const u8, current: ?*Dentry_T, root: *Dentry_T) VfsErr_T!*Dentry_T {
    const dentries = fmt.broken_str(path, '/', &allocator.sba.allocator)
    catch |err| switch(err) {
        error.WithoutSub => return root,
        else => return VfsErr_T.PathResolveError,
    };
    defer {
        allocator.sba.allocator.free(dentries) catch {
            @branchHint(.unlikely);
            // klog()
        };
    }
    if(root.d_sblock == null) return VfsErr_T.NoNFound;
    if(root.child == null) {
        root.child = root.d_sblock.?.inode_op.lookup.?(root, dentries[0]) catch
            return VfsErr_T.NoNFound;
        root.child.?.parent = root;
        root.child.?.younger_brother = null;
        root.child.?.older_brother = null;
        root.child.?.child = null;
    }
    var current_dentry: *Dentry_T = if(current != null) current.? else root.child.?;
    for(dentries, 0..) |dentry, i| {
        sw: switch((enum { step0, step1 }).step0) {
            .step0 => {
                @branchHint(.likely);
                var next: ?*Dentry_T = current_dentry;
                while(next != null) : (next = next.?.younger_brother) {
                    if(mem.eql(next.?.d_name, dentry, .{ .case = true })) {
                        @branchHint(.cold);
                        if(i + 1 >= dentries.len) return next.?;
                        if(next.?.child == null) {
                            @branchHint(.cold);
                            next.?.child = next.?.d_op.?.lookup.?(next.?, dentries[i + 1]) catch
                                return VfsErr_T.NoNFound;
                            next.?.child.?.parent = next;
                        }
                        if(next.?.d_inode.?.type != .directory) return VfsErr_T.NoNFound;
                        current_dentry = next.?.child.?;
                        break :sw {};
                    }
                }
                continue :sw .step1;
            },
            .step1 => {
                @branchHint(.unlikely);
                current_dentry.younger_brother = current_dentry.parent.?.d_op.?.lookup.?(current_dentry.parent.?, dentry) catch
                    return VfsErr_T.NoNFound;
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

pub inline fn perm_decode(dentry: *Dentry_T, gid: []const types.gid_T, uid: types.uid_T) types.perm_T {
    if(dentry.d_inode.?.uid == uid)
        return dentry.d_inode.?.mode.owner;
    for(dentry.d_inode.?.gid) |inode_gid|
        if(inode_gid == gid)
            return dentry.d_inode.?.mode.group;
    return dentry.d_inode.?.mode.other;
}

pub inline fn is_valid_op(dentry: *Dentry_T, op: Op_T) VfsErr_T!void {
    const file_type: types.FileType_T = r: {
        if(dentry == &main.root) break :r .directory;
        if(dentry.d_inode == null or dentry.d_op == null) return VfsErr_T.InvalidDentry;
        break :r dentry.d_inode.?.type;
    };
    switch(file_type) {
        .block, .char, .regular => {
            return switch(op) {
                .read => if(dentry.d_op.?.read == null) VfsErr_T.InvalidOperation,
                .write => if(dentry.d_op.?.write == null) VfsErr_T.InvalidOperation,
                .unlink => if(dentry.d_op.?.unlink == null) VfsErr_T.InvalidOperation,
                .chmod => if(dentry.d_op.?.chmod == null) VfsErr_T.InvalidOperation,
                .chown => if(dentry.d_op.?.chown == null) VfsErr_T.InvalidOperation,
                .exec => unreachable, // TODO:
                else => VfsErr_T.InvalidOperation,
            };
        },
        .directory, .link => {
            return switch(op) {
                .unlink => if(dentry.d_op.?.unlink == null) VfsErr_T.InvalidOperation,
                .create => if(dentry.d_op.?.create == null) VfsErr_T.InvalidOperation,
                .mkdir => if(dentry.d_op.?.mkdir == null) VfsErr_T.InvalidOperation,
                .chmod => if(dentry.d_op.?.chmod == null) VfsErr_T.InvalidOperation,
                .chown => if(dentry.d_op.?.chown == null) VfsErr_T.InvalidOperation,
                else => VfsErr_T.InvalidOperation,
            };
        },
    }
}
