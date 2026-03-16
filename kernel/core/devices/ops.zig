// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ops.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const aux: type = @import("aux.zig");
const main: type = @import("main.zig");
const vfs: type = @import("root").interfaces.vfs;

pub fn ioctl(
    major: types.Major_T,
    minor: types.Minor_T,
    command: usize,
    data: ?*anyopaque
) anyerror!usize {
    const dev_info: *const types.DevBranch_T = try aux.major_ptr(major);
    if(!aux.is_valid_minor(major, minor)) return types.DevErr_T.MinorNoExist;
    try aux.is_valid_op(dev_info.dev.ops, .ioctl);
    return dev_info.dev.ops.ioctl.?(minor, command, data);
}

pub fn mount(
    major: types.Major_T,
    minor: types.Minor_T
) anyerror!*const vfs.Superblock_T {
    const dev_info: *const types.DevBranch_T = try aux.major_ptr(major);
    if(!aux.is_valid_minor(major, minor)) return types.DevErr_T.MinorNoExist;
    try aux.is_valid_op(dev_info.dev.ops, .mount);
    return dev_info.dev.ops.mount.?(minor);
}

pub fn umount(
    major: types.Major_T,
    minor: types.Minor_T
) anyerror!void {
    const dev_info: *const types.DevBranch_T = try aux.major_ptr(major);
    if(!aux.is_valid_minor(major, minor)) return types.DevErr_T.MinorNoExist;
    try aux.is_valid_op(dev_info.dev.ops, .umount);
    return dev_info.dev.ops.umount.?(minor);
}

pub fn open(
    major: types.Major_T,
    minor: types.Minor_T
) anyerror!void {
    const dev_info: *const types.DevBranch_T = try aux.major_ptr(major);
    if(!aux.is_valid_minor(major, minor)) return types.DevErr_T.MinorNoExist;
    try aux.is_valid_op(dev_info.dev.ops, .open);
    return dev_info.dev.ops.open.?(minor);
}

pub fn close(
    major: types.Major_T,
    minor: types.Minor_T
) anyerror!void {
    const dev_info: *const types.DevBranch_T = try aux.major_ptr(major);
    if(!aux.is_valid_minor(major, minor)) return types.DevErr_T.MinorNoExist;
    try aux.is_valid_op(dev_info.dev.ops, .close);
    return dev_info.dev.ops.close.?(minor);
}

pub fn read(
    major: types.Major_T,
    minor: types.Minor_T,
    offset: usize
) anyerror![]u8 {
    const dev_info: *const types.DevBranch_T = try aux.major_ptr(major);
    if(!aux.is_valid_minor(major, minor)) return types.DevErr_T.MinorNoExist;
    try aux.is_valid_op(dev_info.dev.ops, .read);
    return dev_info.dev.ops.read.?(minor, offset);
}

pub fn write(
    major: types.Major_T,
    minor: types.Minor_T,
    src: []const u8,
    offset: usize
) anyerror!void {
    const dev_info: *const types.DevBranch_T = try aux.major_ptr(major);
    if(!aux.is_valid_minor(major, minor)) return types.DevErr_T.MinorNoExist;
    try aux.is_valid_op(dev_info.dev.ops, .write);
    return dev_info.dev.ops.write.?(minor, src, offset);
}
