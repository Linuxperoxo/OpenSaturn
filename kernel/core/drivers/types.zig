// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const MajorNum_T: type = if(@sizeOf(usize) > 1) u16 else u8;

pub const OpsErr_T: type = error {
    FAILED,
    NOCMD,
    UNREACHABLE,
};

pub const DriverErr_T: type = error {
    MinorRewritten,
    InternalError,
    Blocked,
    NoNFound,
    NullFound,
    MinorCollision,
};

pub const Ops_T: type = struct {
    open: ?*const fn() DriverErr_T!void,
    close: ?*const fn() void,
    minor: ?*const fn(minor: MajorNum_T) DriverErr_T!void,
    read: *const fn(offset: usize) []u8,
    write: *const fn([]const u8) void,
    ioctrl: *const fn(C: usize, D: usize) OpsErr_T!usize,
};

// Usar align para membros que podem ser null
// garente sua localizacao correta na memoria
pub const Driver_T: type = struct {
    major: ?MajorNum_T align(@sizeOf(usize)) = null,
    ops: ?Ops_T align(@sizeOf(usize)) = null,
};

pub const DriversBunch_T: type = struct {
    bunch: [4]?*Driver_T = .{ null, null, null, null },
    flags: struct {
        lock: u1 = 0,
        full: u1 = 0,
    },
};
