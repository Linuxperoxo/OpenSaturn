// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const SOA: type = @import("root").memory.SOA;
const modules: type = @import("root").modules;

const Optimize_T: type = SOA.Optimize_T;
const Cache_T: type = SOA.Cache_T;

const Driver_T: type = @import("types.zig").Driver_T;
const Ops_T: type = @import("types.zig").Ops_T;

pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
const SOAAllocator_T: type = SOA.buildObjAllocator(
    Driver_T,
    false,
    64,
    .{
        .alignment = @enumFromInt(@sizeOf(usize)),
        .range = .large,
        .type = .linear,
    },
    .{}
);

var allocator: SOAAllocator_T = .{};

pub fn alloc() AllocatorErr_T!*Driver_T {
    return @call(.always_inline, &SOAAllocator_T.alloc, .{
        &allocator
    });
}

pub fn free(obj: *Driver_T) AllocatorErr_T!void {
    return @call(.always_inline, &SOAAllocator_T.free, .{
        &allocator, obj
    });
}
