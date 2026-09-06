// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocators.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub const sba: type = struct {
    const buildByteAllocator = @import("root").lib.kernel.alloc.sba.buildByteAllocator;
    pub var allocator = buildByteAllocator(null, .{}) {};
};
