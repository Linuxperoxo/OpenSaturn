// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const buildByteAllocator = @import("sba.zig").buildByteAllocator;

pub const sba: type = struct {
    pub var allocator = buildByteAllocator(null, .{
        .resize = true
    }) {};
};
