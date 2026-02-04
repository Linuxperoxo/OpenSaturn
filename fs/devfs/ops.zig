// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ops.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").interfaces.vfs;
const kfs: type = @import("root").interfaces.fs;
const mem: type = @import("root").lib.utils.mem;
const fmt: type = @import("root").lib.utils.fmt;
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

pub fn devfs_mount() anyerror!*const Superblock_T {
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
    if(parent.d_private == null) return types.DevfsErr_T.CorruptFilesystem;

    const dev_list: *types.DevfsList_T = @ptrCast(@alignCast(parent.d_private.?));
    if(!dev_list.is_initialized() or dev_list.how_many_nodes() == 0)
        return types.DevfsErr_T.DeviceNoFound;

    return dev_list.iterator_handler(
        child,
        &opaque {
            pub fn handler(dentry: *Dentry_T, device_name: []const u8) anyerror!void {
                if(!mem.eql(dentry.d_name, device_name, .{ .case = true }))
                    return error.Continue;
            }
        }.handler,
    ) catch |err| return switch(err) {
        types.DevfsListErr_T.EndOfIterator => types.DevfsErr_T.DeviceNoFound,
        else => types.DevfsErr_T.UnexpectedAction,
    };
}

pub fn create_device_node(major: devices.Major_T, minor: devices.Minor_T, uid: uid_T, gid: gid_T, mode: mode_T) anyerror!void {
    if(!devices.valid_major(major)) return types.DevfsErr_T.InvalidMajor;
    if(devices.valid_minor(major, minor)) return types.DevfsErr_T.InvalidMinor;

    const dev_list: *types.DevfsList_T = @ptrCast(@alignCast(if(dfs.devfs_superblock.private_data != null) dfs.devfs_superblock.? else r: {
        dfs.devfs_superblock.private_data = &(allocator.sba.allocator.alloc(types.DevfsList_T, 1)
            catch return types.DevfsErr_T.UnexpectedAction)[0];
        break :r dfs.devfs_superblock.private_data.?;
    }));

    const device = try aux.new_dentry_device(major, minor, uid, gid, mode);
    errdefer {
        allocator.sba.allocator.free(device.d_inode.?) catch unreachable;
        allocator.sba.allocator.free(device.d_private.?) catch unreachable;
        allocator.sba.allocator.free(device.d_name) catch unreachable;
        allocator.sba.allocator.free(device) catch unreachable;
    }
    try dev_list.push_in_list(&allocator.sba.allocator, device);
}

pub fn unlink_device_node(major: devices.Major_T, minor: devices.Minor_T) anyerror!void {
    _ = major;
    _ = minor;
}
