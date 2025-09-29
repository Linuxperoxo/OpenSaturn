// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: search.zig    │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const PhysIo_T: type = @import("types.zig").PhysIoType_T;
const PhysIoType_T: type = @import("types.zig").PhysIoType_T;

pub const Level0_T: type = struct {
    vendor: ?*[12]?*Level1_T,
    map: u4,
};

pub const Level1_T: type = packed struct {
    devices: ?*[4]?*Level2_T,
    map: u4,
};

pub const Level2_T: type = struct {
    devices: ?*[8]*?PhysIo_T,
    map: u8,
};

pub const SearchReturn_T: type = union {
    devices: *[8]*?PhysIo_T,
    phys: *PhysIo_T,
};

pub const SearchErr_T: type = error {
    NonFound,
};

var physIoRoot= [_]?*Level0_T {
    null
} ** 16;

pub fn physIoSearch(phys: PhysIoType_T) SearchErr_T!*SearchReturn_T {
    return if(physIoRoot[@intFromEnum(phys.class)] == null) SearchErr_T.NonFound else r: {
        if(physIoRoot[@intFromEnum(phys.class)].?.vendor == null) break :r SearchErr_T.NonFound;
        if(physIoRoot[@intFromEnum(phys.class)].?.vendor.?[@intFromEnum(phys.vendor)] == null) break :r SearchErr_T.NonFound;
        t: {
            if(physIoRoot[@intFromEnum(phys.class)].?.vendor.?[@intFromEnum(phys.vendor)].?.devices == null) break :r SearchErr_T.NonFound;
            if(physIoRoot[@intFromEnum(phys.class)].?.vendor.?[@intFromEnum(phys.vendor)].?.devices.?[phys.device orelse break :t {}] == null) break :r SearchErr_T.NonFound;
            break :r .{
                .device = physIoRoot[@intFromEnum(phys.class)].?.vendor.?[@intFromEnum(phys.vendor)].?.devices.?[phys.device.?].?,
            };
        }
        break :r .{
            .devices = physIoRoot[@intFromEnum(phys.class)].?.vendor.?[@intFromEnum(phys.vendor)].?.devices.?,
        };
    };
}
