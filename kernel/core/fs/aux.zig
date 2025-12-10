// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const main: type = @import("main.zig");
const types: type = @import("types.zig");
const c: type = @import("root").kernel.utils.c;
const mem: type = @import("root").kernel.utils.mem;

pub fn check_init() types.FsErr_T!void {
    errdefer {
        // critical error! klog()
    }
    if(!c.c_bool(main.fs_register.flags.init)) {
        try main.fs_register.fs.init();
        main.fs_register.flags.init = 1;
    }
}

pub fn search_by_fs(fs: ?*types.Fs_T, fs_name: ?[]const u8) types.FsErr_T!?struct { *types.Fs_T, ?types.Collision_T } {
    if(!c.c_bool(main.fs_register.fs.how_many_nodes)) return null;
    var param: struct {
        to_cmp_ptr: ?*types.Fs_T,
        to_cmp_name: ?[]const u8,
        collision: ?types.Collision_T,
    } = .{
        .to_cmp_ptr = fs,
        .to_cmp_name = fs_name,
        .collision = null,
    };
    return .{
        main.fs_register.fs.iterator_handler(
            &param,
            &opaque {
                pub fn handler(iterator_fs: *types.Fs_T, src: *@TypeOf(param)) anyerror!void {
                    if(src.to_cmp_ptr != null and src.to_cmp_ptr.? == iterator_fs) {
                        src.collision = .pointer; return;
                    }
                    if(src.to_cmp_name != null and mem.eql(src.to_cmp_name.?, iterator_fs.name, .{ .case = false })) {
                        src.collision = .name; return;
                    }
                    return error.Continue;
                }
            },
        ) catch |err| switch(err) {
            @TypeOf(main.fs_register.fs).ListErr_T.EndOfIterator => null,
            else => return types.FsErr_T.FsRegisterFailed,
        },
        param.collision,
    };
}
