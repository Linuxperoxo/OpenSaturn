// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Mod_T: type = @import("interfaces.zig").Mod_T;
const ModErr_T: type = @import("interfaces.zig").ModErr_T;
const Allocator: type = @import("interfaces.zig").Allocator;

const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const registerfs = @import("root").interfaces.fs.registerfs;
const unregisterfs = @import("root").interfaces.fs.unregisterfs;

const ModS_T: type = enum(u2) {
    uninitialized,
    running,
    undefined,
};

const ModInfo_T: type = struct {
    next: ?*@This(),
    prev: ?*@This(),
    status: ModS_T,
    this: ?*Mod_T,
};

var moduleRoot: ModInfo_T = .{
    .next = null,
    .prev = null,
    .status = .undefined,
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

fn resolveType(mod: *Mod_T) anyerror!void {
    switch(mod.type) {
        .filesystem => {
            @call(.never_inline, &registerfs, .{
                (@as(*Fs_T, @alignCast(@ptrCast(mod.private.?)))).*
            }) catch |err| {
                return err;
            };
        },
        .syscall => unreachable, // TODO:
        .driver => unreachable, // TODO:
    }
}

pub fn inmod(
    mod: Mod_T,
) ModErr_T!void {
    var current: ?*ModInfo_T = moduleRoot.next;
    var prev: *ModInfo_T = &moduleRoot;

    while(current) |_| {
        if(prev.this != null and
            @call(.always_inline, &cmp_name, .{mod.name, prev.this.?.name})
        ) return ModErr_T.IsInitialized;
        prev = current.?;
        current = current.?.next;
    }
    prev.next = alloc: {
        const allocArea = @call(.never_inline, &Allocator.kmalloc, .{
            ModInfo_T,
            1
        }) catch {
            return ModErr_T.InternalError;
        };
        allocArea[0].next = null;
        allocArea[0].prev = prev;
        break :alloc &allocArea[0];
    };
    prev.next.?.this = alloc: {
        const allocArea = @call(.never_inline, &Allocator.kmalloc, .{
            Mod_T,
            1
        }) catch {
            return ModErr_T.InternalError;
        };
        allocArea[0] = mod;
        break :alloc &allocArea[0];
    };
    @call(.always_inline, &resolveType, .{prev.next.?.this.?}) catch {
        return ModErr_T.InternalError;
    };
}

pub fn rmmod(
    _: []const u8
) ModErr_T!void {

}
