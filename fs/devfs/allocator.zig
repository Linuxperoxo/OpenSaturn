// ┌──────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: allocator.zig    │
// │            Author: Linuxperoxo                   │
// └──────────────────────────────────────────────────┘

const buildByteAllocator = @import("root").lib.kernel.alloc.sba.buildByteAllocator;

pub const sba: type = struct {
    pub var allocator = buildByteAllocator(null, .{}) {};
};
