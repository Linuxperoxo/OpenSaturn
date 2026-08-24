// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ops.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").interfaces.vfs;
const kfs: type = @import("root").interfaces.fs;
const mem: type = @import("root").lib.kernel.mem;
const fmt: type = @import("root").lib.kernel.fmt;
const dfs: type = @import("fs.zig");
const aux: type = @import("aux.zig");
const types: type = @import("types.zig");
const devices: type = @import("root").interfaces.devices;
const allocator: type = @import("allocator.zig");

const Dentry_T: type = vfs.Dentry_T;
const Superblock_T: type = vfs.Superblock_T;
const FileType_T: type = vfs.FileType_T;
const InodeOp_T: type = vfs.InodeOp_T;
const Inode_T: type = vfs.Inode_T;
const VfsErr_T: type = vfs.VfsErr_T;
const mode_T: type = vfs.mode_T;
const uid_T: type = vfs.uid_T;
const gid_T: type = vfs.gid_T;

const Fs_T: type = kfs.Fs_T;
const FsErr_T: type = kfs.FsErr_T;

var devices_list: types.DevfsList_T = .{};

pub fn devfs_mount(_: []const u8) anyerror!*const Superblock_T {
    dfs.devfs_superblock.private_data = &devices_list;
    return &dfs.devfs_superblock;
}

pub fn devfs_umount() anyerror!void {
    return error.InternalError;
}

pub fn write(dentry: *Dentry_T, src: []const u8, offset: usize) anyerror!void {
    const dev: *const types.DevfsPrivate_T = try aux.dentry_device_info(dentry);
    return devices.write(dev.major, dev.minor, src, offset);
}

pub fn read(dentry: *Dentry_T, offset: usize) anyerror![]u8 {
    const dev: *const types.DevfsPrivate_T = try aux.dentry_device_info(dentry);
    return devices.read(dev.major, dev.minor, offset);
}

pub fn chmod(dentry: *Dentry_T, mode: mode_T) anyerror!void {
    dentry.d_inode.?.mode = mode;
}

pub fn chown(dentry: *Dentry_T, uid: uid_T, gid: gid_T) anyerror!void {
    dentry.d_inode.?.uid = uid;
    dentry.d_inode.?.gid = gid;
}

pub fn ioctl(dentry: *Dentry_T, command: usize, data: *anyopaque) anyerror!usize {
    const dev: *const types.DevfsPrivate_T = try aux.dentry_device_info(dentry);
    return devices.ioctl(dev.major, dev.minor, command, data);
}

pub fn lookup(parent: *Dentry_T, child: []const u8) anyerror!*Dentry_T {
    if(parent.d_sblock == null
        or parent.d_sblock.?.private_data == null
        or @as(@TypeOf(&devices_list), @ptrCast(@alignCast(parent.d_sblock.?.private_data.?))) != &devices_list) return types.DevfsErr_T.CorruptFilesystem;

    if(!devices_list.is_initialized())
        return types.DevfsErr_T.DeviceNoFound;

    return devices_list.iterator_handler(child, &opaque {
        pub fn handler(device_dentry: *Dentry_T, device_target_name: @TypeOf(child)) anyerror!void {
            if(!mem.eql(device_dentry.d_name, device_target_name, .{}))
                return error.Continue;
        }
    }.handler) catch |err| return switch(err) {
        types.DevfsListErr_T.EndOfIterator => types.DevfsErr_T.DeviceNoFound,
        else => types.DevfsErr_T.ListOperationFailed,
    };
}

pub fn create_device_node(major: devices.Major_T, minor: devices.Minor_T, uid: uid_T, gid: gid_T, mode: mode_T) anyerror!void {
    if(!devices.valid_major(major)) return types.DevfsErr_T.InvalidMajor;
    if(!devices.valid_minor(major, minor)) return types.DevfsErr_T.InvalidMinor;

    if(!devices_list.is_initialized())
        try devices_list.init(&allocator.sba.allocator);

    const device = try aux.new_dentry_device(major, minor, uid, gid, mode);
    errdefer {
        allocator.sba.allocator.free(device.d_inode.?) catch unreachable;
        allocator.sba.allocator.free(@as(*vfs.Inode_T, @alignCast(@ptrCast(device.d_private.?)))) catch unreachable;
        allocator.sba.allocator.free(@constCast(device.d_name)) catch unreachable;
        allocator.sba.allocator.free(device) catch unreachable;
    }
    try devices_list.push_in_list(&allocator.sba.allocator, device);
}

pub fn unlink_device_node(major: devices.Major_T, minor: devices.Minor_T) anyerror!void {
    _ = major;
    _ = minor;
}
