// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const MajorNum_T: type = u6;
const MinorNum_T: type = u8; // TMP

pub const OpsErr_T: type = error {
    FAILED,
    NOCMD,
    UNREACHABLE,
};

pub const DriverErr_T: type = error {
    InternalError,
    Blocked,
    NonFound,
    MajorCollision,
    OutMajor,
    DoubleFree,
};

pub const Ops_T: type = struct {
    read: *const fn(minor: MinorNum_T, offset: usize) []u8,
    write: *const fn(minor: MinorNum_T, data: []const u8) void,
    ioctrl: *const fn(minor: MinorNum_T, command: usize, data: usize) OpsErr_T!usize,
    minor: *const fn(minor: MinorNum_T) DriverErr_T!void,
    open: ?*const fn(minor: MinorNum_T) DriverErr_T!void,
    close: ?*const fn(minor: MinorNum_T) void,
};

pub const Driver_T: type = struct {
    major: MajorNum_T,
    ops: Ops_T,
};

pub const Radix: type = struct {
    pub const Level1: type = struct {
        line: [16]?*Level2,
        map: u16,
    };

    pub const Level2: type = struct {
        line: ?[4]Level3,
        map: u4,
    };

    pub const Level3: type = struct {
        line: ?[4]Driver_T,
        map: u4,
    };
};
