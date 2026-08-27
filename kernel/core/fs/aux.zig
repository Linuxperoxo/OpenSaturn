// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const main: type = @import("main.zig");
const types: type = @import("types.zig");
const c: type = @import("root").lib.kernel.c;
const mem: type = @import("root").lib.kernel.mem;
const allocator: type = @import("allocator.zig");

pub fn checkInit() types.FsErr!void {
    if(!c.cBool(main.fs_register.flags.init)) {
        main.fs_register.fs.init(&allocator.sba.allocator) catch {
            // critical error! klog()
            return types.FsErr.InitFailed;
        };
        main.fs_register.flags.init = 1;
    }
}

pub fn searchByFs(fs: ?*types.Fs, fs_name: ?[]const u8) types.FsErr!struct { *types.Fs, ?types.Collision } {
    if(!c.cBool(main.fs_register.fs.howManyNodes())) return types.FsErr.NoNFound;
    var param: struct {
        to_cmp_ptr: ?*types.Fs,
        to_cmp_name: ?[]const u8,
        collision: ?types.Collision,
    } = .{
        .to_cmp_ptr = fs,
        .to_cmp_name = fs_name,
        .collision = null,
    };
    return .{
        main.fs_register.fs.iteratorHandler(
            &param,
            &opaque {
                pub fn handler(iterator_fs: *types.Fs, src: *@TypeOf(param)) anyerror!void {
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
            @TypeOf(main.fs_register.fs).ListErr.EndOfIterator => types.FsErr.NoNFound,
            else => types.FsErr.FsRegisterFailed,
        },
        param.collision,
    };
}
