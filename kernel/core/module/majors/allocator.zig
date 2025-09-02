// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const SOA: type = @import("root").memory.SOA;
const Modules: type = @import("root").modules;
const MajorNode_T: type = @import("types.zig").MajorNode_T;

const Allocator_T: type = SOA.buildObjAllocator(MajorNode_T, Modules.__SaturnAllMods__.len);
pub const AllocatorErr_T: type = Allocator_T.err_T;

var SOAAllocator = A: {
    var initialAllocator: Allocator_T = undefined;
    initialAllocator.obja = 0;
    initialAllocator.objf = null;
    for(0..Modules.__SaturnAllMods__.len) |i| {
        initialAllocator.objm[i] = .free;
    }
    break :A initialAllocator;
};

pub fn alloc() AllocatorErr_T!*MajorNode_T {
    return @call(.always_inline, &Allocator_T.alloc, .{
        &SOAAllocator
    });
}

pub fn free(O: *MajorNode_T) AllocatorErr_T!void {
    const base: usize = @intFromPtr(&SOAAllocator.objs);
    return @call(.always_inline, &Allocator_T.free, .{ &SOAAllocator,
            ((@intFromPtr(O) - base) / @sizeOf(MajorNode_T)) - 1
    });
}
