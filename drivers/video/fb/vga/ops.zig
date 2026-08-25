// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ops.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const phys: type = @import("root").__SaturnArchImpl__.physio;
const config: type = @import("config.zig");
const types: type = @import("types.zig");
const devices: type = @import("root").interfaces.devices;

pub var pci_physio_video: ?*phys.PhysIo = null;

// ===================== AUX

pub inline fn setVideoPhysio() types.FbErr!void {
    pci_physio_video = phys.physioSearch(.{
        .identified = .{
            .class = .display,
            .vendor = switch(comptime config.video_vendor) {
                .qemu => .qemu,
                .amd => .amd,
                .intel => .intel,
                .nvidia => .nvidia,
            },
        },
    }) catch return types.FbErr.ExpectNoNFound;
    // map bars to virtual
}

pub inline fn unsetVideoPhysio() void {
    pci_physio_video = null;
}

pub inline fn checkVideoPhysio() types.FbErr!void {
    if(pci_physio_video == null
        or pci_physio_video.?.status == .missing) return types.FbErr.MissingDevice;
}

// ===================== OPS

pub noinline fn write(_: devices.Minor, data: []const u8, offset: usize) types.FbErr!void {
    try checkVideoPhysio();
    _ = data;
    _ = offset;
}

pub noinline fn read(_: devices.Minor, offset: usize) types.FbErr![]u8 {
    try checkVideoPhysio();
    _ = offset;
    return @constCast("Hello, World!"); // NOTE: TEST
}

pub noinline fn ioctl(_: devices.Minor, command: usize, data: ?*anyopaque) types.FbErr!usize {
    try checkVideoPhysio();
    return sw: switch(@as(types.FbCommands, @enumFromInt(command))) {
        .color => {
            if(data == null) break :sw types.FbErr.UnexpectedData;
            unreachable;
        },

        .move => {
            if(data == null) break :sw types.FbErr.UnexpectedData;
            unreachable;
        },

        .put => {
            if(data == null) break :sw types.FbErr.UnexpectedData;
            unreachable;
        },

        .load => {
            if(data == null) break :sw types.FbErr.UnexpectedData;
            unreachable;
        },

        .clear => {
            break :sw 0;
        },

        _ => types.FbErr.InvalidCommand,
    };
}
