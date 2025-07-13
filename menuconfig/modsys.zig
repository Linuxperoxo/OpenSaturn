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
                        @compileError("");
                    }
                    count += 1;
                }
            }
            break :block1 count;
        };
        var names: [modulesLinkable][]u8 = undefined;
        var namesI: u32 = 0;
        for(0..saturnMods.len) |i| {
            if(@hasDecl(saturnMods[i], "__linkable_module_name__")) {
                names[namesI] = @constCast(saturnMods[i].__linkable_module_name__);
                namesI += 1;
            }
        }
        break :block0 names;
    };
    var buffer: [2]u8 = .{undefined, '\n'};
    std.debug.print("======== Saturn Modules ========\n", .{});
    for(modulesNames) |_| {
        buffer[0] = stdin.readByte() catch unreachable;
        buffer[0] = stdin.readByte() catch unreachable;
        buffer[0] = stdin.readByte() catch unreachable;
        buffer[0] = stdin.readByte() catch unreachable;
        buffer[0] = stdin.readByte() catch unreachable;
    }
    std.debug.print("================================\n", .{});
}
