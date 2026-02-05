// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ops.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const phys: type = @import("root").ar.target_code.physio;
const config: type = @import("config.zig");
const types: type = @import("types.zig");
const devices: type = @import("root").interfaces.devices;

var pci_physio_video: ?*phys.PhysIo_T = null;

pub inline fn video_physio() types.FbErr_T!void {
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
    asm volatile(
        // DEBUG
        \\ jmp .
        \\ jmp 0xAA000
        :
        :[_] "{eax}" (pci_physio_video)
    );
}

pub noinline fn write(_: devices.Minor_T, data: []const u8, offset: usize) anyerror!void {
    _ = data;
    _ = offset;
}

pub noinline fn read(_: devices.Minor_T, offset: usize) anyerror![]u8 {
    _ = offset;
    return @constCast("Hello, World!");
}

pub noinline fn ioctl(_: devices.Minor_T, command: usize, data: ?*anyopaque) anyerror!usize {
    _ = command;
    _ = data;
    return 0;
}
