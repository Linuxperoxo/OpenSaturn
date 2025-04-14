// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: video.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const devices: type = @import("root").libsat.kernel;
const drivers: type = @import("root").drivers;
const video: type = @import("root").video;

pub const videoDevice: devices.DeviceInterface = .{
    .deviceName = &[_:0]u8{'v', 'i', 'd', 'e', 'o'},
    .deviceDriver =  switch(video.activeDriver) {
        .vga => video.activeDriver.vga,
        .vesa => video.activeDriver.vesa,
    },
};

pub fn setVideoDriver(Driver: drivers.DriverInterface) void {
    videoDevice.deviceDriver = Driver;
}
