// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const types: type = @import("types.zig");

const buildByteAllocator = @import("root").kernel.memory.sba.buildByteAllocator;

pub const sba: type = struct {
    pub var allocator = buildByteAllocator(null, .{
        .resize = true,
    }) {};

    pub fn alloc_one(comptime T: type) types.RootfsErr_T!*T {
        return &(allocator.alloc(T, 1)
            catch return types.RootfsErr_T.AllocatorFailed)[0];
    }
};
