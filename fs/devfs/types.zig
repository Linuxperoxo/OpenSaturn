// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const devices: type = @import("root").interfaces.devices;
const list: type = @import("root").lib.utils.list;
const vfs: type = @import("root").interfaces.vfs;

pub const DevfsList_T: type = list.BuildList(*vfs.Dentry_T);
pub const DevfsListErr_T: type = DevfsList_T.ListErr_T;

pub const DevfsPrivate_T: type = struct {
    major: devices.Major_T,
    minor: devices.Minor_T,
    device: *const devices.Dev_T,
};

pub const DevfsErr_T: type = error {
    CorruptDentry,
    CorruptFilesystem,
    DeviceNoFound,
    UnexpectedAction,
    InvalidMajor,
    InvalidMinor,
    AllocatorFailed,
    ListOperationFailed,
};
