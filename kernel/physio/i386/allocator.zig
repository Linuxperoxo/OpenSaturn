// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const memory: type = if(!builtin.is_test) @import("root").lib.memory.sba else @import("test/sba.zig");
const types: type = @import("types.zig");

pub const sba: type = struct {
    const buildByteAllocator = memory.buildByteAllocator;
    const Allocator_T: type = buildByteAllocator(
        null,
        .{
            .resize = true,
        },
    );

    pub const AllocatorErr_T: type = Allocator_T.err_T;

    pub var allocator: Allocator_T = .{};
    var firts_call: bool = true;

    pub fn alloc_type_single(comptime T: type) AllocatorErr_T!*T {
        firts_call = r: {
            if(firts_call)
                allocator.root.bytes = null;
            break :r false;
        };
        return &(try @call(.never_inline, Allocator_T.alloc, .{
            &allocator, T, 1
        }))[0];
    }

    pub fn free_type_single(comptime T: type, ptr: *T) AllocatorErr_T!void {
        const slice: []T = @as([*]T, @ptrCast(ptr))[0..1];
        return @call(.never_inline, Allocator_T.free, .{
            &allocator, slice
        });
    }
};
