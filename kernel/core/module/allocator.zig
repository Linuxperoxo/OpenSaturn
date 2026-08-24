// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const builtin: type = @import("builtin");

const buildByteAllocator = if(!builtin.is_test) @import("root").lib.kernel.alloc.sba.buildByteAllocator;

pub const sba: type = struct {
    pub var allocator = buildByteAllocator(null, .{}) {};
};
