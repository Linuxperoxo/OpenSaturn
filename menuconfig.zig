// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: menuconfig.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const std: type = @import("std");
const ModulesInfos = @import("modules.zig").__SaturnModulesInfos__;

pub fn main() void {
    const stdin = std.io.getStdIn().reader();
    const fd: i32 = @intCast(std.os.linux.open(".config.sm", .{.CREAT = true, .TRUNC = true, .ACCMODE = .RDWR}, 0b110000000));
    defer _ = std.os.linux.close(fd);
    if(ModulesInfos.len == 0) {
        return;
    }
    var buffer: [2]u8 = .{undefined, '\n'};
    for(ModulesInfos) |mod| {
        if(mod.optional) {
            std.debug.print("Module: {s} (y/n): ", .{mod.name});
            buffer[0] = stdin.readByte() catch unreachable;
            _ = std.os.linux.write(fd, mod.name.ptr, mod.name.len);
            _ = std.os.linux.write(fd, "=", 1);
            buffer[0] = b: {
                if(buffer[0] != 'y' and buffer[0] != 'n') {
                    break :b 'n';
                }
                break :b buffer[0];
            };
            _ = std.os.linux.write(fd, buffer[0..2], 2);
        }
    }
}
