// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocators.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const memory: type = @import("root").kernel.memory;

pub const sba: type = struct {
    pub var allocator = memory.sba.buildByteAllocator(null, .{}) {};
    pub const err_T: type = @TypeOf(allocator).err_T;
};
