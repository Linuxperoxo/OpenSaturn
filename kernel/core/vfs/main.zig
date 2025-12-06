// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
//const fs: type = @import("root").core.fs;
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const kernel: type = @import("root").kernel;

const mem: type = @import("test/mem.zig");
const fmt: type = @import("test/fmt.zig");

const Inode_T: type = types.Inode_T;
const InodeOp_T: type = types.InodeOp_T;
const SuperBlock_T: type = types.Superblock_T;
const Dentry_T: type = types.Dentry_T;
const VfsErr_T: type = types.VfsErr_T;

var root: Dentry_T = .{
    .d_name = "/",
    .d_inode = null,
    .d_sblock = null,
    .d_op = null,
    .d_private = null,
    .child = null,
    .brother = null,
    .parent = null,
};

pub fn resolve_path(path: []const u8, current: ?*Dentry_T) VfsErr_T!*Dentry_T {
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
                current_dentry.brother = current_dentry.parent.?.d_op.?.lookup(current_dentry.parent.?, dentry) catch
                    return VfsErr_T.NoNFound;
                current_dentry = current_dentry.brother.?;
                continue :sw .step0;
            },
        }
    }
    allocator.sba.allocator.free(dentries) catch {
        // klog()
    };
    return current_dentry;
}

pub fn mount(
    path: []const u8,
    current: ?*Dentry_T,
    //fs_struct: *const fs.interfaces.Fs_T
) VfsErr_T!void {
    const dentry_mount: *Dentry_T = try resolve_path(path, current);
    if(dentry_mount.d_sblock != null) return VfsErr_T.AlreadyMounted;
    //const sblock = fs_struct.mount() catch return VfsErr_T.FilesystemMountError;
    //dentry_mount.d_sblock = sblock;
    //dentry_mount.d_op = sblock.inode_op;
}

pub fn umount(_: []const u8) VfsErr_T!void {

}


