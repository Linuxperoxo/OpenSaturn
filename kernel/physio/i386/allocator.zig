// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const memory: type = if(!builtin.is_test) @import("root").lib.kernel.memory else @import("test_sba.zig");
const types: type = @import("types.zig");

pub const sba: type = struct {
    const buildByteAllocator = if(!builtin.is_test) memory.sba.buildByteAllocator else memory.buildByteAllocator;
    const Allocator_T: type = buildByteAllocator(
        null,
        .{
            .resize = true,
        },
    );

    pub const AllocatorErr_T: type = Allocator_T.err_T;

    var allocator: Allocator_T = .{};

    pub fn alloc(bytes: u32) AllocatorErr_T![]u8 {
        return @call(.always_inline, Allocator_T.alloc, .{
            &allocator, bytes
        });
    }

    pub fn free(ptr: []u8) AllocatorErr_T!void {
        return @call(.always_inline, Allocator_T.free, .{
            &allocator, ptr
        });
    }
};
