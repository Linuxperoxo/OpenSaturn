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
        send: *const fn(DriverCommand) DriverResponse,
        receive: *const fn(DriverCommand) DriverResponse,
    },
};

