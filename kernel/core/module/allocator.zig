// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const memory: type = @import("root").kernel.memory;

pub const sba: type = struct {
    pub const allocator = memory.sba.buildByteAllocator(null, .{}) {};
};
