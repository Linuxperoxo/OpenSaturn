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

const Dentry: type = vfs.Dentry;
const Superblock: type = vfs.Superblock;
const FileType: type = vfs.FileType;
const InodeOp: type = vfs.InodeOp;
const Inode: type = vfs.Inode;
const VfsErr: type = vfs.VfsErr;
const Mode: type = vfs.Mode;
const Uid: type = vfs.Uid;
const Gid: type = vfs.Gid;

const Fs: type = kfs.Fs;
const FsErr: type = kfs.FsErr;

var devices_list: types.DevfsList = .{};

pub fn devfsMount(_: []const u8) anyerror!*const Superblock {
    dfs.devfs_superblock.private_data = &devices_list;
    return &dfs.devfs_superblock;
}

pub fn devfsUmount() anyerror!void {
    return error.InternalError;
}

pub fn write(dentry: *Dentry, src: []const u8, offset: usize) anyerror!void {
    const dev: *const types.DevfsPrivate = try aux.dentryDeviceInfo(dentry);
    return devices.write(dev.major, dev.minor, src, offset);
}

pub fn read(dentry: *Dentry, offset: usize) anyerror![]u8 {
    const dev: *const types.DevfsPrivate = try aux.dentryDeviceInfo(dentry);
    return devices.read(dev.major, dev.minor, offset);
}

pub fn chmod(dentry: *Dentry, mode: Mode) anyerror!void {
    dentry.d_inode.?.mode = mode;
}

pub fn chown(dentry: *Dentry, uid: Uid, gid: Gid) anyerror!void {
    dentry.d_inode.?.uid = uid;
    dentry.d_inode.?.gid = gid;
}

pub fn ioctl(dentry: *Dentry, command: usize, data: *anyopaque) anyerror!usize {
    const dev: *const types.DevfsPrivate = try aux.dentryDeviceInfo(dentry);
    return devices.ioctl(dev.major, dev.minor, command, data);
}

pub fn lookup(parent: *Dentry, child: []const u8) anyerror!*Dentry {
    if(parent.d_sblock == null
        or parent.d_sblock.?.private_data == null
        or @as(@TypeOf(&devices_list), @ptrCast(@alignCast(parent.d_sblock.?.private_data.?))) != &devices_list) return types.DevfsErr.CorruptFilesystem;

    if(!devices_list.isInitialized())
        return types.DevfsErr.DeviceNoFound;

    return devices_list.iteratorHandler(child, &opaque {
        pub fn handler(device_dentry: *Dentry, device_target_name: @TypeOf(child)) anyerror!void {
            if(!mem.eql(device_dentry.d_name, device_target_name, .{}))
                return error.Continue;
        }
    }.handler) catch |err| return switch(err) {
        types.DevfsListErr.EndOfIterator => types.DevfsErr.DeviceNoFound,
        else => types.DevfsErr.ListOperationFailed,
    };
}

pub fn createDeviceNode(major: devices.Major, minor: devices.Minor, uid: Uid, gid: Gid, mode: Mode) anyerror!void {
    if(!devices.isAValidMajor(major)) return types.DevfsErr.InvalidMajor;
    if(!devices.isAValidMinor(major, minor)) return types.DevfsErr.InvalidMinor;

    if(!devices_list.isInitialized())
        try devices_list.init(&allocator.sba.allocator);

    const device = try aux.newDentryDevice(major, minor, uid, gid, mode);
    errdefer {
        allocator.sba.allocator.free(device.d_inode.?) catch unreachable;
        allocator.sba.allocator.free(@as(*vfs.Inode, @alignCast(@ptrCast(device.d_private.?)))) catch unreachable;
        allocator.sba.allocator.free(@constCast(device.d_name)) catch unreachable;
        allocator.sba.allocator.free(device) catch unreachable;
    }
    try devices_list.pushInList(&allocator.sba.allocator, device);
}

pub fn unlinkDeviceNode(major: devices.Major, minor: devices.Minor) anyerror!void {
    _ = major;
    _ = minor;
}
