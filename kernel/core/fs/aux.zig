// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const main: type = @import("main.zig");
const types: type = @import("types.zig");
const c: type = @import("root").lib.utils.c;
const mem: type = @import("root").lib.utils.mem;
const allocator: type = @import("allocator.zig");

pub fn check_init() types.FsErr_T!void {
    if(!c.c_bool(main.fs_register.flags.init)) {
        main.fs_register.fs.init(&allocator.sba.allocator) catch {
            // critical error! klog()
            return types.FsErr_T.InitFailed;
        };
        main.fs_register.flags.init = 1;
    }
}

pub fn search_by_fs(fs: ?*types.Fs_T, fs_name: ?[]const u8) types.FsErr_T!struct { *types.Fs_T, ?types.Collision_T } {
    if(!c.c_bool(main.fs_register.fs.how_many_nodes())) return types.FsErr_T.NoNFound;
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
            }.handler,
        ) catch |err| return switch(err) {
            @TypeOf(main.fs_register.fs).ListErr_T.EndOfIterator => types.FsErr_T.NoNFound,
            else => types.FsErr_T.FsRegisterFailed,
        },
        param.collision,
    };
}
