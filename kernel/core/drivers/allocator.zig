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

const Driver_T: type = @import("types.zig").Driver_T;
const Ops_T: type = @import("types.zig").Ops_T;

const AllocatorErr_T: type = Allocator_T.err_T;
const Allocator_T: type = SOA.buildObjAllocator(
    Driver_T,
    modules.countModOfType(.driver),
    CacheSize_T.auto,
    null,
    null,
    null,
    Align_T.in16,
    Optimize_T.linear,
    Cache_T.PrioritizeHits,
    CacheTry_T.Insistent,
);

comptime {
    @export(&Allocator, .{
        .name = "allocator.drivers",
        .section = ".data.saturn.allocator",
    });
}

const AllocatorPtr: *Allocator_T = @constCast(Allocator);
const Allocator = r: {
    var AllocTmp: Allocator_T = undefined;
    AllocTmp.init();
    break :r AllocTmp;
};

pub fn alloc() AllocatorErr_T!*Driver_T {
    @call(.always_inline, AllocatorPtr.alloc, .{
        AllocatorPtr
    });
}

pub fn free(OBJ: *Driver_T) AllocatorErr_T!void {
    @call(.always_inline, AllocatorPtr.free, .{
        AllocatorPtr, ((@intFromPtr(OBJ) - @intFromPtr(&AllocatorPtr.objs[0])) / @sizeOf(Driver_T))
    });
}
