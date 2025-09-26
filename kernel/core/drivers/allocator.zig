// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const memory: type = @import("memory.zig");
const modules: type = @import("root").modules;

const SOA: type = memory.SOA;
const Optimize_T: type = SOA.Optimize_T;
const Cache_T: type = SOA.Cache_T;

const Driver_T: type = @import("types.zig").Driver_T;
const Ops_T: type = @import("types.zig").Ops_T;

pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
const SOAAllocator_T: type = SOA.buildObjAllocator(
    Driver_T,
    false,
    r: {
        if(memory.totalOfPossibleAllocs <= 4) break :r 4;
        if((memory.totalOfPossibleAllocs % 2) != 0) break :r memory.totalOfPossibleAllocs + 1;
        break :r memory.totalOfPossibleAllocs;
    },
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

pub fn free(obj: ?*Driver_T) AllocatorErr_T!void {
    return if(obj == null) {} else @call(.always_inline, &SOAAllocator_T.free, .{
        &allocator, obj.?
    });
}

pub fn haveAllocs() bool {
    return if(@import("builtin").is_test) allocator.allocs != 0 else @compileError(
        "fn haveAllocs run in test mode only"
    );
}
