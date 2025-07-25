// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module-sys.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

// OPTIMIZE:
// FIXME:

const std: type = @import("std");
const modules: type = @import("saturn/modules");

pub fn main() void {
    const stdin = std.io.getStdIn().reader();
    const modulesNames = comptime block0: {
        const saturnMods = modules.__SaturnAllMods__;
        const modulesLinkable = block1: {
            var count: usize = 0;
            for(saturnMods) |module| {
                if(@hasDecl(module, "__linkable_module_name__")) {
                    if((@TypeOf(module.__linkable_module_name__) != []const u8)) {
                        @compileError(
                            \\ __linkable_module_name__ is defined in the file but does not follow the Saturn Standard Module Def,
                            \\ the definition must be 'pub const __linkable_module_name__: []const u8 = __linkable__.name'
                        );
                    }
                    if(@hasDecl(module, "__linkable_module_arch__")) {} else {} // TODO:
                    if(@hasDecl(module, "__linkable_module_opti__")) {
                        if(module.__linkable_module_opti__) {
                            count += 1;
                        }
                    }
                }
            }
            break :block1 count;
        };
        var names: [modulesLinkable][]u8 = undefined;
        var namesI: u32 = 0;
        for(0..saturnMods.len) |i| {
            if(@hasDecl(saturnMods[i], "__linkable_module_name__")) {
                if(@hasDecl(saturnMods[i], "__linkable_module_opti__")) {
                    if(saturnMods[i].__linkable_module_opti__) {
                        names[namesI] = @constCast(saturnMods[i].__linkable_module_name__);
                        namesI += 1;
                    }
                }
            }
        }
        break :block0 names;
    };
    const fd: i32 = @intCast(std.os.linux.open("modules.sm", .{.CREAT = true, .TRUNC = true, .ACCMODE = .RDWR}, 0b110000000));
    defer _ = std.os.linux.close(fd);
    if(modulesNames.len > 0) {
        var buffer: [2]u8 = .{undefined, '\n'};
        std.debug.print("======== Saturn Modules ========\n", .{});
        for(modulesNames) |moduleName| {
            std.debug.print("Module: {s} (y/n): ", .{moduleName});
            buffer[0] = stdin.readByte() catch unreachable;
            _ = std.os.linux.write(fd, moduleName.ptr, moduleName.len);
            _ = std.os.linux.write(fd, "=", 1);
            buffer[0] = verify: {
                if(buffer[0] != 'y' and buffer[0] != 'n') {
                    break :verify 'n';
                }
                break :verify buffer[0];
            };
            _ = std.os.linux.write(fd, buffer[0..2], 2);
        }
        std.debug.print("================================\n", .{});
    }
    std.debug.print("All Done!\n", .{});
}
