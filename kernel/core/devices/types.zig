// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const MinorNum_T: type = u8;

pub const Dev_T: type = struct {
    major: @import("root").interfaces.drivers.types.MajorNum_T,
    minor: MinorNum_T,
    type: enum {
        char,
        block
    },
};

pub const DevErr_T: type = error {
    MinorCollision,
    Locked,
    OutOfMinor,
    InternalError,
    MinorDoubleFree,
    NonMinor,
    MajorReturnError,
};

pub const DevMajorBunch_T: type = struct {
    bunch: [16]?*const Dev_T,
    alloc: u16,
    miss: u16,
    part: ?u4,
};
