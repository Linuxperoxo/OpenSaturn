// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocators.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const builtin: type = @import("builtin");

pub const sba: type = struct {
    const buildByteAllocator = if(!builtin.is_test) @import("root").kernel.memory.sba.buildByteAllocator else
        @import("test/sba.zig").buildByteAllocator;
    pub var allocator = buildByteAllocator(null, .{}) {};
};
