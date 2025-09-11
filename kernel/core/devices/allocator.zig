// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const SOA: type = @import("root").memory.SOA;
const modules: type = @import("root").modules;

const Align_T: type = SOA.Align_T;
const Cache_T: type = SOA.Cache_T;
const CacheSize_T: type = SOA.CacheSize_T;
const CacheTry_T: type = SOA.CacheTry_T;
const Hits_T: type = SOA.Hits_T;
const Optimize_T: type = SOA.Optimize_T;

const Dev_T: type = @import("types.zig").Dev_T;

pub const AllocatorErr_T: type = Allocator_T.err_T;
const Allocator_T: type = SOA.buildObjAllocator(
    Dev_T,
    8,
    .auto,
    null,
    null,
    null,
    .in16,
    .optimized,
    .PrioritizeHits,
    .Insistent,
);

var Allocator = r: {
    var AllocTmp: Allocator_T = undefined;
    @call(.compile_time, Allocator_T.init, .{
        &AllocTmp
    });
    break :r AllocTmp;
};

pub fn alloc() AllocatorErr_T!*Dev_T {
    return @call(.always_inline, &Allocator_T.alloc, .{
        &Allocator
    });
}

pub fn free(OBJ: *Dev_T) AllocatorErr_T!void {
    return @call(.always_inline, &Allocator_T.free, .{
        &Allocator, (@intFromPtr(OBJ) - @intFromPtr(&Allocator.objs[0])) / @sizeOf(Dev_T)
    });
}
