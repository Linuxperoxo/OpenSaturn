// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: Allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const meta: type = @import("root").lib.kernel.meta;

pub const Error: type = error{
    WithoutMemory,
    InternalError,
    NoInitilized,
    InvalidOperation,
};

pub const VTable: type = struct {
    alloc: *const fn (*anyopaque, usize) Error![]u8,
    free: *const fn (*anyopaque, []u8) void,
    resize: ?*const fn (*anyopaque, []u8, usize) Error![]u8 = null,
};

private: *anyopaque,
vtable: *const VTable,

const Self: type = @This();

/// * alloc a slice of type []T containing "n" elements
pub noinline fn alloc(self: *const Self, comptime T: type, n: usize) Error![]T {
    return @ptrCast(@alignCast(try @call(.auto, self.vtable.alloc, .{ self.private, @sizeOf(T) * n })));
}

/// * free a slice
pub noinline fn free(self: *const Self, ptr: anytype) void {
    if (!comptime meta.isSlice(@TypeOf(ptr)))
        @compileError("\"fn free()\" expect a slice!");

    @call(.auto, self.vtable.free, .{ self.private, @as([]u8, @ptrCast(@alignCast(ptr))) });
}

/// * alloc a single element pointer
pub noinline fn create(self: *const Self, comptime T: type) Error!*T {
    return @ptrCast(@alignCast(try @call(.auto, self.vtable.alloc, .{ self.private, @sizeOf(T) })));
}

/// * free a single element pointer
pub noinline fn destroy(self: *const Self, ptr: anytype) void {
    if (!comptime meta.isSinglePointer(@TypeOf(ptr)))
        @compileError("\"fn destroy()\" expect a one element pointer!");

    @call(.auto, self.vtable.free, .{ self.private, @as([]u8, @ptrCast(ptr)) });
}

/// * readjusts the size of a slice
/// * depending on the implementation, you can allocate a new slice and copy the old data, or just expand the old slice
pub noinline fn resize(self: *const Self, ptr: anytype, new_size: usize) Error![]meta.child(@TypeOf(ptr)) {
    if (!comptime meta.isSlice(@TypeOf(ptr)))
        @compileError("\"fn resize()\" expect a slice!");

    return if (self.vtable.resize == null) Error.InvalidOperation else @ptrCast(@alignCast(@call(.auto, self.vtable.resize.?, .{ self.private, ptr, new_size })));
}
