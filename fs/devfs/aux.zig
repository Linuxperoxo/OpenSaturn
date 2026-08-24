// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").interfaces.vfs;
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const dfs: type = @import("fs.zig");
const devices: type = @import("root").interfaces.devices;
const fmt: type = @import("root").lib.kernel.fmt;

pub inline fn check_init(dev_list: *types.DevfsList_T) types.DevfsListErr_T!void {
    if(!dev_list.is_initialized())
        try dev_list.init(&allocator.sba.allocator);
}

pub inline fn dentry_device_info(dentry: *vfs.Dentry_T) types.DevfsErr_T!*const types.DevfsPrivate_T {
    if(dentry.d_private == null)
        return types.DevfsErr_T.CorruptDentry;
    return @ptrCast(@alignCast(dentry.d_private.?));
}

var inode_count: usize = 0;
pub inline fn new_dentry_device(major: devices.Major_T, minor: devices.Minor_T, uid: vfs.uid_T, gid: vfs.gid_T, mode: vfs.mode_T) anyerror!*vfs.Dentry_T {
    const new_dentry: *vfs.Dentry_T = &(try allocator.sba.allocator.alloc(vfs.Dentry_T, 1))[0];
    errdefer allocator.sba.allocator.free(new_dentry) catch unreachable;

    const new_device_node: *types.DevfsPrivate_T = &(try allocator.sba.allocator.alloc(types.DevfsPrivate_T, 1))[0];
    errdefer allocator.sba.allocator.free(new_device_node) catch unreachable;

    const new_device_inode: *vfs.Inode_T = &(try allocator.sba.allocator.alloc(vfs.Inode_T, 1))[0];
    errdefer allocator.sba.allocator.free(new_device_inode) catch unreachable;

    const new_device_name: []u8 = try fmt.format(&allocator.sba.allocator, "{s}{d}", .{
        devices.dev_info(major, .name) catch unreachable,
        minor,
    });

    new_dentry.* = .{
        .d_name = new_device_name,
        .d_inode = new_device_inode,
        .d_op = &dfs.devfs_ops,
        .d_sblock = null,
        .d_private = new_device_node,
        .child = null,
        .parent = null,
        .older_brother = null,
        .younger_brother = null,
    };

    new_device_inode.* = .{
        .uid = uid,
        .gid = gid,
        .mode = mode,
        .nlinks = 0,
        .inode = inode_count,
        .type = .char,
        .data_block = @intFromPtr(new_dentry),
        .data_inode = @intFromPtr(new_dentry),
    };

    inode_count += 1;
    return new_dentry;
}
