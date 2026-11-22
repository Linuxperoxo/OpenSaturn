const Allocator: type = @import("Allocator.zig");

pub fn CompileAllocator(comptime T: type, comptime size: comptime_int) type {
    const Bitmap: type = @import("bitmap.zig").Bitmap(size);

    comptime {
        if (@sizeOf(T) == 0)
            @compileError("CompileAllocator requires a non-zero-sized pool element type");
        if (size <= 0)
            @compileError("CompileAllocator pool size must be greater than zero");
    }

    return struct {
        const Self: type = @This();

        pool: [size]T,
        bitmap: Bitmap,

        pub const Empty: Self = .{
            .pool = undefined,
            .bitmap = Bitmap.init(),
        };

        const vtable: Allocator.VTable = .{
            .init = @ptrCast(init),
            .deinit = @ptrCast(deinit),
            .alloc = alloc,
            .free = free,
            .resize = null,
        };

        pub fn init(self: *Self) Allocator.Err!void {
        }

        pub fn deinit(self: *Self) void {
        }
    };
}
