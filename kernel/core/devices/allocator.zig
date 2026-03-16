// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const buildByteAllocator = @import("root").lib.memory.sba.buildByteAllocator;

pub const sba: type = struct {
    pub const allocator = buildByteAllocator(null, .{}) {};
};
