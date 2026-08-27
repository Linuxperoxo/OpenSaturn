// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const memory: type = @import("root").lib.kernel.alloc.sba;
const types: type = @import("types.zig");

pub const sba: type = struct {
    const buildByteAllocator = memory.buildByteAllocator;
    const Allocator: type = buildByteAllocator(
        null,
        .{
            .resize = true,
        },
    );

    pub const AllocatorErr: type = Allocator.Err;

    pub var allocator: Allocator = .{};
    var firts_call: bool = true;

    pub fn allocTypeSingle(comptime t: type) AllocatorErr!*t {
        firts_call = r: {
            if(firts_call)
                allocator.root.bytes = null;
            break :r false;
        };
        return &(try @call(.never_inline, Allocator.alloc, .{
            &allocator, t, 1
        }))[0];
    }

    pub fn freeTypeSingle(comptime t: type, ptr: *t) AllocatorErr!void {
        const slice: []t = @as([*]t, @ptrCast(ptr))[0..1];
        return @call(.never_inline, Allocator.free, .{
            &allocator, slice
        });
    }
};
