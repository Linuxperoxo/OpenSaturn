// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: drivers.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const video: type = @import("video/video.zig");

pub const DriverCommand: type = struct {
    command: u8,
    args: [*]u8 = undefined,
};

pub const DriverResponse: type = union(enum(u2)) {
    ret: u32,
    err: DriverError,
    non: void,
};

pub const DriverError:type = enum(u4) {
    Noerror,
    InvalidCommand,
    DeviceBusy,
    NotSupported,
    Unknown,
};

pub const DriverInterface: type = struct {
    IOctrl: struct {
        write: *const fn(DriverCommand) DriverResponse,
        read: *const fn(DriverCommand) DriverResponse,
        err: ?*const fn(DriverCommand) DriverResponse,
    },
};

