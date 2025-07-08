// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Fs_T: type = @import("root").interfaces.fs.Fs_T;
const FsErr_T: type = @import("root").interfaces.fs.FsErr_T;

const Allocator: type = @import("interfaces.zig").Allocator;

const FsInfo_T: type = struct {
    next: ?*@This(),
    prev: ?*@This(),
    this: ?*Fs_T,
};

var fsRegisted: FsInfo_T = .{
    .next = null,
    .prev = null,
    .this = null,
};

pub fn cmp_name(
    noalias s0: []const u8,
    noalias s1: []const u8
) bool {
    if(s0.len != s1.len) {
        return false;
    }
    for(0..s0.len) |i| {
        if(s0[i] != s1[i]) {
            return false;
        }
    }
    return true;
}

fn registerFirstFs(fs: *Fs_T) FsErr_T!void {
    fsRegisted.this = alloc: {
        const allocArea = @call(.never_inline, &Allocator.kmalloc, .{
            Fs_T,
            1
        }) catch {
            return FsErr_T.InternalError;
        };
        allocArea[0] = fs.*;
        break :alloc &allocArea[0];
    };
    slcRegFn = 1;
}

fn registerOtherFs(fs: *Fs_T) FsErr_T!void {
    var current: ?*FsInfo_T = fsRegisted.next;
    var prev: *FsInfo_T = &fsRegisted;
    while(current) |_| {
        if(prev.this != null and
            @call(.always_inline, &cmp_name, .{prev.this.?.name, fs.name})
        ) return FsErr_T.Rewritten;
        prev = current.?;
        current = current.?.next;
    }
    prev.next = alloc: {
        const allocArea = @call(.never_inline, &Allocator.kmalloc, .{
            FsInfo_T,
            1
        }) catch {
            return FsErr_T.InternalError;
        };
        allocArea[0].next = null;
        allocArea[0].prev = prev;
        break :alloc &allocArea[0];
    };
    prev.next.?.this = alloc: {
        const allocArea = @call(.never_inline, &Allocator.kmalloc, .{
            Fs_T,
            1
        }) catch {
            return FsErr_T.InternalError;
        };
        allocArea[0] = fs.*;
        break :alloc &allocArea[0];
    };
}

// Flag apenas para controlar a primeira execuçao
// ja que vamos executar registerFirstFs 1 vez fiz
// isso ai mesmo
var slcRegFn: u1 = 0;
pub fn registerfs(
    fs: Fs_T
) FsErr_T!void {
    const fnRegister: [2]*const fn(*Fs_T) FsErr_T!void = comptime .{
        &registerFirstFs,
        &registerOtherFs,
    };
    @call(.never_inline, fnRegister[slcRegFn], .{@constCast(&fs)}) catch |err| {
        return err;
    };
    @import("root").debug.breakpoint(&fsRegisted.this, .eax);
}

pub fn unregisterfs(
    _: []const u8
) FsErr_T!void {
    
}
