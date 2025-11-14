// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: allocator.zig  │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const memory: type = if(!builtin.is_test) @import("root").lib.kernel.memory.sba else @import("test_sba.zig");
const types: type = @import("types.zig");

pub const sba: type = struct {
    const buildByteAllocator = memory.buildByteAllocator;
    const Allocator_T: type = buildByteAllocator(
        null,
        .{
            .resize = true,
        },
    );

    pub const AllocatorErr_T: type = Allocator_T.err_T;

    var allocator: Allocator_T = .{};
    var firts_call: bool = true;

    fn alloc(bytes: u32) AllocatorErr_T![]u8 {
        // apenas para evitar problema do ponteiro
        // iniciar apontando para um lugar invalido
        firts_call = r: {
            if(firts_call)
                allocator.root.bytes = null;
            break :r false;
        };
        return @call(.always_inline, Allocator_T.alloc, .{
            &allocator, bytes
        });
    }

    fn free(ptr: []u8) AllocatorErr_T!void {
        return @call(.always_inline, Allocator_T.free, .{
            &allocator, ptr
        });
    }

    pub fn alloc_type_single(comptime T: type) AllocatorErr_T!*T {
        return @alignCast(@ptrCast(
            (try @call(.never_inline, alloc, .{
                @sizeOf(T)
            })).ptr
        ));
    }

    pub fn free_type_single(comptime T: type, ptr: *T) AllocatorErr_T!void {
        return @call(.never_inline, free, .{
            @as([*]u8, @ptrCast(ptr))[0..@sizeOf(T)]
        });
    }
};
