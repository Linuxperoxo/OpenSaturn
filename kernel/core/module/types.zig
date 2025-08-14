// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Interfaces
pub const Mod_T: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    type: ModType_T,
    init: *const fn() ModErr_T!void,
    exit: *const fn() ModErr_T!void,
    private: ?*anyopaque,
};

pub const ModType_T: type = enum(u2) {
    driver,
    filesystem,
    syscall,
};

pub const ModErr_T: type = error {
    IsInitialized,
    NoNInitialized,
    AllocatorError,
    InternalError,
};

// Internal
pub const ModMajorStatus_T: type = enum {
    running,
    sleeping,
};

pub const ModMajor_T: type = struct {
    next: ?*@This(),
    status: ?ModMajorStatus_T,
    module: ?Mod_T,
};

pub const MajorInfo_T: type = struct {
    majors: ?*ModMajor_T,
    in: *const fn(*const Mod_T) ModErr_T!void,
    rm: *const fn(*const Mod_T) ModErr_T!void,
};
