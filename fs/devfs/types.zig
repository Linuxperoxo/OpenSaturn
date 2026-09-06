// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const devices: type = @import("root").interfaces.devices;
const list: type = @import("root").lib.kernel.linked_list;
const vfs: type = @import("root").interfaces.vfs;

pub const DevfsList: type = list.buildList(*vfs.Dentry);
pub const DevfsListErr: type = DevfsList.ListErr;

pub const DevfsPrivate: type = struct {
    major: devices.Major,
    minor: devices.Minor,
};

pub const DevfsErr: type = error {
    CorruptDentry,
    CorruptFilesystem,
    DeviceNoFound,
    UnexpectedAction,
    InvalidMajor,
    InvalidMinor,
    AllocatorFailed,
    ListOperationFailed,
};
