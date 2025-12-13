// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
const main: type = @import("main.zig");
const types: type = @import("types.zig");
const mem: type = @import("test/mem.zig");

var modules = r: {
    var mods = [_]types.Mod_T {
        types.Mod_T {
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
            .after = null,
            .exit = &opaque {
                pub fn exit() types.ModErr_T!void {}
            }.exit,
            .private = .{
                .filesystem = {}
            },
            .flags = .{
                .control = .{
                    .anon = 0,
                    .call = .{
                        .exit = 0,
                        .remove = 1,
                        .after = 0,
                        .init = 0,
                    },
                },
                .internal = .{
                    .installed = 0,
                    .removed = 0,
                    .collision = .{
                        .name = 0,
                        .pointer = 0,
                    },
                    .call = .{
                        .init = 0,
                        .exit = 0,
                        .after = 0,
                    },
                    .fault = .{
                        .call = .{
                            .init = 0,
                            .after = 0,
                            .exit = 0,
                        },
                        .remove = 0,
                    },
                },
            },
        }
    } ** 1;
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
        if(module.flags.internal.installed != 1 and module.flags.internal.removed != 0) return error.InstalledFlagNotSync;
        const module_found = try main.srchmod(
            module.name, module.type
        );
        if(!mem.eql(module_found.name, module.name, .{ .case = true})) return error.IncorrectData;
    }
    if(main.test_fn.entry_init_flag(0) != 1) return error.DeinitFailed;
}

test "Module Remove" {
    for(&modules) |*module| {
        module.flags.control.anon = 1;
        if(main.srchmod(module.name, module.type)) |_| {
            return error.AnonModuleExpose;
        } else |_| {}
        module.flags.control.anon = 0;
        module.flags.control.call.remove = 0;
        if(main.rmmod(module)) |_| {
            return error.ModuleWithoutRemovePermWasRemoved;
        } else |_| {}
        module.flags.control.call.remove = 1;
        try main.rmmod(module);
        if(module.flags.internal.installed != 0 and module.flags.internal.removed != 1) return error.RemovedFlagNotSync;
        _ = main.srchmod(
            module.name, module.type
        ) catch continue;
        return error.FoundRemovedModule;
    }
    if(main.test_fn.entry_init_flag(0) != 0) return error.InitFailed;
}
