// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ops.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const aux: type = @import("aux.zig");
const main: type = @import("main.zig");
const vfs: type = @import("root").interfaces.vfs;

pub fn ioctl(
    major: types.Major,
    minor: types.Minor,
    command: usize,
    data: ?*anyopaque
) anyerror!usize {
    const dev_info: *const types.DevBranch = try aux.majorPtr(major);
    if(!aux.isValidMinor(major, minor)) return types.DevErr.MinorNoExist;
    try aux.isValidOp(dev_info.dev.ops, .ioctl);
    return dev_info.dev.ops.ioctl.?(minor, command, data);
}

pub fn mount(
    major: types.Major,
    minor: types.Minor
) anyerror!*const vfs.Superblock {
    const dev_info: *const types.DevBranch = try aux.majorPtr(major);
    if(!aux.isValidMinor(major, minor)) return types.DevErr.MinorNoExist;
    try aux.isValidOp(dev_info.dev.ops, .mount);
    return dev_info.dev.ops.mount.?(minor);
}

pub fn umount(
    major: types.Major,
    minor: types.Minor
) anyerror!void {
    const dev_info: *const types.DevBranch = try aux.majorPtr(major);
    if(!aux.isValidMinor(major, minor)) return types.DevErr.MinorNoExist;
    try aux.isValidOp(dev_info.dev.ops, .umount);
    return dev_info.dev.ops.umount.?(minor);
}

pub fn open(
    major: types.Major,
    minor: types.Minor
) anyerror!void {
    const dev_info: *const types.DevBranch = try aux.majorPtr(major);
    if(!aux.isValidMinor(major, minor)) return types.DevErr.MinorNoExist;
    try aux.isValidOp(dev_info.dev.ops, .open);
    return dev_info.dev.ops.open.?(minor);
}

pub fn close(
    major: types.Major,
    minor: types.Minor
) anyerror!void {
    const dev_info: *const types.DevBranch = try aux.majorPtr(major);
    if(!aux.isValidMinor(major, minor)) return types.DevErr.MinorNoExist;
    try aux.isValidOp(dev_info.dev.ops, .close);
    return dev_info.dev.ops.close.?(minor);
}

pub fn read(
    major: types.Major,
    minor: types.Minor,
    offset: usize
) anyerror![]u8 {
    const dev_info: *const types.DevBranch = try aux.majorPtr(major);
    if(!aux.isValidMinor(major, minor)) return types.DevErr.MinorNoExist;
    try aux.isValidOp(dev_info.dev.ops, .read);
    return dev_info.dev.ops.read.?(minor, offset);
}

pub fn write(
    major: types.Major,
    minor: types.Minor,
    src: []const u8,
    offset: usize
) anyerror!void {
    const dev_info: *const types.DevBranch = try aux.majorPtr(major);
    if(!aux.isValidMinor(major, minor)) return types.DevErr.MinorNoExist;
    try aux.isValidOp(dev_info.dev.ops, .write);
    return dev_info.dev.ops.write.?(minor, src, offset);
}
