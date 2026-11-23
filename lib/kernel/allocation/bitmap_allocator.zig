// ┌────────────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: compile_allocator.zig  │
// │                  Author: Linuxperoxo                   │
// └────────────────────────────────────────────────────────┘

const Allocator: type = @import("Allocator.zig");
const std: type = @import("std");

pub fn BitmapAllocator(comptime size: comptime_int) type {
    const Bitmap: type = @import("bitmap.zig").Bitmap(size);

    return struct {
        const Self: type = @This();

        pool: [size]u8,
        bitmap: Bitmap,
        initialized: bool,

        const vtable: Allocator.VTable = .{
            .alloc = @ptrCast(alloc),
            .free = @ptrCast(free),
        };

        pub fn init() Self {
            return Self {
                .pool = undefined,
                .bitmap = Bitmap.init(),
                .initialized = true,
            };
        }

        pub fn deinit(self: *Self) void {
            if(!self.initialized) return;
            self.initialized = false;
            self.allocated = 0;
        }

        pub fn alloc(self: *Self, n: usize) Allocator.Error![]u8 {
            if(!self.initialized) return Allocator.Error.NoInitilized;

            if(self.bitmap.findFirstIndexOfConsecutiveSetBits(.UNSET, n)) |initial| {
                self.bitmap.modifyBitRange(.SET, n, initial);
                return self.pool[initial..(initial + n)];
            }

            return Allocator.Error.WithoutMemory;
        }

        // free without double free
        pub fn free(self: *Self, memory: []u8) void {
            if (!self.initialized or memory.len == 0) return;

            const poolStart: usize = @intFromPtr(self.pool[0..].ptr);
            const memoryStart: usize = @intFromPtr(memory.ptr);
            if (memoryStart < poolStart) return;

            const offset: usize = memoryStart - poolStart;
            if (offset >= size or memory.len > size - offset) return;

            self.bitmap.modifyBitRange(.UNSET, memory.len, offset);
        }

        pub fn allocator(self: *Self) Allocator {
            return Allocator {
                .private = self,
                .vtable = &vtable,
            };
        }
    };
}
