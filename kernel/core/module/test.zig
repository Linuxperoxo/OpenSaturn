// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
const main: type = @import("main.zig");
const types: type = @import("types.zig");
const mem: type = @import("test/mem.zig");

const modules = r: {
    var mods = [_]types.Mod_T {
        .{
            .name = "tester mod",
            .desc = "tester module",
            .version = "0.0.1",
            .author = "Linuxperoxo",
            .license = .{
                .know = .GPL2_only
            },
            .type = .filesystem,
            .deps = null,
            .init = &opaque {
                pub fn init() types.ModErr_T!void {}
            }.init,
            .exit = &opaque {
                pub fn exit() types.ModErr_T!void {}
            }.exit,
            .private = .{
                .filesystem = {}
            }
        }
    } ** 8;
    for(0..mods.len) |i| {
        var num: [1]u8 = .{
            '0'
        };
        num[0] += i;
        mods[i].name = mods[i].name ++ num;
    }
    break :r mods;
};

test "Module Install And Search" {
    if(main.test_fn.entry_init_flag(0) != 0) return error.InitFailed;
    for(&modules) |*module| {
        try main.inmod(module);
        const module_found = try main.srchmod(
            module.name, module.type
        );
        if(!mem.eql(module_found.name, module.name, .{ .case = true})) return error.IncorrectData;
    }
    if(main.test_fn.entry_init_flag(0) != 1) return error.DeinitFailed;
}

test "Module Remove" {
    for(&modules) |*module| {
        try main.rmmod(module);
        _ = main.srchmod(
            module.name, module.type
        ) catch continue;
        return error.FoundRemovedModule;
    }
    if(main.test_fn.entry_init_flag(0) != 0) return error.InitFailed;
}
