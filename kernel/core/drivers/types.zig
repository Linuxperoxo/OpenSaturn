// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const MajorNum_T: type = u6;
pub const MinorNum_T: type = u8; // TMP

pub const OpsErr_T: type = error {
    NoCMD,
    Failed,
    Unreachable,
};

pub const DriverErr_T: type = error {
    InternalError,
    Blocked,
    NonFound,
    MajorCollision,
    OutMajor,
    DoubleFree,
    MinorCollision,
    UndefinedMajor,
    UndefinedMinor,
    Unreachable,
};

pub const Ops_T: type = struct {
    read: *const fn(minor: MinorNum_T, offset: usize) DriverErr_T![]u8,
    write: *const fn(minor: MinorNum_T, data: []const u8) DriverErr_T!void,
    ioctrl: *const fn(minor: MinorNum_T, command: usize, data: usize) OpsErr_T!usize,
    minor: *const fn(minor: MinorNum_T) DriverErr_T!void,
    open: ?*const fn(minor: MinorNum_T) DriverErr_T!void,
    close: ?*const fn(minor: MinorNum_T) DriverErr_T!void,
};

pub const Driver_T: type = struct {
    major: MajorNum_T,
    ops: Ops_T,
};

