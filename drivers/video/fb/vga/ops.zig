// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ops.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const phys: type = @import("root").ar.target_code.physio;
const config: type = @import("config.zig");
const types: type = @import("types.zig");
const devices: type = @import("root").interfaces.devices;

var pci_physio_video: ?*phys.PhysIo_T = null;

// ===================== AUX

pub inline fn set_video_physio() types.FbErr_T!void {
    pci_physio_video = phys.physio_search(.{
        .identified = .{
            .class = .display,
            .vendor = switch(comptime config.VideoVendor) {
                .qemu => .qemu,
                .amd => .amd,
                .intel => .intel,
                .nvidia => .nvidia,
            },
        },
    }) catch return types.FbErr_T.ExpectNoNFound;
    // map bars to virtual
}

pub inline fn unset_video_physio() void {
    pci_physio_video = null;
}

pub inline fn check_video_physio() types.FbErr_T!void {
    if(pci_physio_video == null
        or pci_physio_video.?.status == .missing) return types.FbErr_T.MissingDevice;
}

// ===================== OPS

pub noinline fn write(_: devices.Minor_T, data: []const u8, offset: usize) types.FbErr_T!void {
    try check_video_physio();
    _ = data;
    _ = offset;
}

pub noinline fn read(_: devices.Minor_T, offset: usize) types.FbErr_T![]u8 {
    try check_video_physio();
    _ = offset;
    return @constCast("Hello, World!");
}

pub noinline fn ioctl(_: devices.Minor_T, command: usize, data: ?*anyopaque) types.FbErr_T!usize {
    try check_video_physio();
    return sw: switch(@as(types.FbCommands_T, @enumFromInt(command))) {
        .color => {
            if(data == null) break :sw types.FbErr_T.UnexpectedData;
            unreachable;
        },

        .move => {
            if(data == null) break :sw types.FbErr_T.UnexpectedData;
            unreachable;
        },

        .put => {
            if(data == null) break :sw types.FbErr_T.UnexpectedData;
            unreachable;
        },

        .load => {
            if(data == null) break :sw types.FbErr_T.UnexpectedData;
            unreachable;
        },

        .clear => {
            break :sw 0;
        },

        _ => types.FbErr_T.InvalidCommand,
    };
}
