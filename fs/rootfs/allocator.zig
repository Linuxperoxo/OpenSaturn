// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub const buildByteAllocator: type = @import("root").kernel.memory.sba.buildByteAllocator;

pub const sba: type = struct {
    pub const allocator = buildByteAllocator(null, .{
        .resized = true,
    }) {};

    pub fn alloc_one(comptime T: type) anyerror!*T {
        return &(allocator.alloc(T, 1)
            catch @import("types.zig").RootfsErr_T.AllocatorFailed)[0];
    }
};
