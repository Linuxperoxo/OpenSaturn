// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const SOA: type = @import("memory.zig").SOA;

const Cache_T: type = SOA.Cache_T;
const Optimize_T: type = SOA.Optimize_T;

pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
const SOAAllocator_T: type = SOA.buildObjAllocator(
    @import("types.zig").Dev_T,
    false,
    256,
    .{
        .alignment = @enumFromInt(@sizeOf(usize)),
        .range = .large,
        .type = .linear,
    },
    .{}
);

var allocator: SOAAllocator_T = .{};

pub fn alloc() AllocatorErr_T!*SOAAllocator_T.Options.Type {
    return @call(.always_inline, &SOAAllocator_T.alloc, .{
        &allocator
    });
}

pub fn free(obj: ?*SOAAllocator_T.Options.Type) AllocatorErr_T!void {
    return if(obj == null) {} else @call(.always_inline, &SOAAllocator_T.free, .{
        &allocator, obj.?
    });
}

pub fn haveAllocs() bool {
    return if(@import("builtin").is_test) allocator.allocs != 0 else @compileError(
        "fn haveAllocs run in test mode only"
    );
}
