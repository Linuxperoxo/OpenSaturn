// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const types: type = @import("types.zig");

const buildByteAllocator = @import("root").lib.kernel.alloc.sba.buildByteAllocator;

pub const sba: type = struct {
    pub var allocator = buildByteAllocator(null, .{
        .resize = true,
    }) {};

    pub fn allocOne(comptime t: type) types.RootfsErr!*t {
        return &(allocator.alloc(t, 1)
            catch return types.RootfsErr.AllocatorFailed)[0];
    }
};
