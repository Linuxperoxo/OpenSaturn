// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const types: type = @import("types.zig");
const kernel: type = @import("root").kernel;

const allocator: type = if(!builtin.is_test) @import("allocator.zig") else
    @import("test/allocator.zig");
const mem: type = if(!builtin.is_test) kernel.utils.mem else
    @import("test/mem.zig");
const fmt: type = if(!builtin.is_test) kernel.utils.fmt else
    @import("test/fmt.zig");

const Inode_T: type = types.Inode_T;
const InodeOp_T: type = types.InodeOp_T;
const SuperBlock_T: type = types.Superblock_T;
const Dentry_T: type = types.Dentry_T;
const VfsErr_T: type = types.VfsErr_T;

pub fn resolve_path(path: []const u8, current: ?*Dentry_T, root: *Dentry_T) VfsErr_T!*Dentry_T {
    const dentries = fmt.broken_str(path, '/', &allocator.sba.allocator)
    catch |err| switch(err) {
        error.WithoutSub => return &root,
        else => return VfsErr_T.PathResolveError,
    };
    if(root.child == null) return VfsErr_T.NoNFound;
    var current_dentry: *Dentry_T = if(current != null) current.? else root.child.?;
    for(dentries, 0..) |dentry, i| {
        sw: switch((enum { step0, step1 }).step0) {
            .step0 => {
                @branchHint(.likely);
                var next: ?*Dentry_T = current_dentry;
                while(next != null) : (next = next.?.brother) {
                    if(mem.eql(next.?.d_name, dentry, .{ .case = true })) {
                        @branchHint(.cold);
                        if(next.?.child == null) {
                            @branchHint(.cold);
                            if(i + 1 >= dentries.len) return next.?;
                            next.?.child = next.?.d_op.?.lookup(next.?, dentries[i + 1]) catch
                                return VfsErr_T.NoNFound;
                            next.?.child.?.parent = next;
                        }
                        current_dentry = next.?.child.?;
                        break :sw {};
                    }
                }
                continue :sw .step1;
            },
            .step1 => {
                @branchHint(.unlikely);
                current_dentry.younger_brother = current_dentry.parent.?.d_op.?.lookup(current_dentry.parent.?, dentry) catch
                    return VfsErr_T.NoNFound;
                current_dentry = current_dentry.younger_brother.?;
                continue :sw .step0;
            },
        }
    }
    allocator.sba.allocator.free(dentries) catch {
        @branchHint(.unlikely);
        // klog()
    };
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

pub inline fn cmp_op(dentry: *Dentry_T, op: enum { read, write, exec, unlink }) VfsErr_T!void {
    if(dentry.d_inode == null or dentry.d_op == null) {
        // klog()
        return VfsErr_T.InvalidDentry;
    }
    if(op == .unlink) return;
    switch(dentry.d_inode) {
        .block, .char, .regular => {
            return switch(op) {
                .read => if(dentry.d_op.?.read == null) VfsErr_T.InvalidOperation,
                .write => if(dentry.d_op.?.write == null) VfsErr_T.InvalidOperation,
                .exec => unreachable, // TODO:
            };
        },
        else => return VfsErr_T.InvalidOperation,
    }
}
