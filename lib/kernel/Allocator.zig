// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: Allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const meta: type = @import("root").lib.kernel.meta;

pub const Err: type = error{
    WithoutMemory,
    InternalError,
    ResizeImpossible,
    NoInitilized,
    InitFailed,
    InvalidOperation,
};

pub const VTable: type = struct {
    init: *const fn (*anyopaque) Err!void,
    deinit: *const fn (*anyopaque) Err!void,
    alloc: *const fn (*anyopaque, usize) Err![]u8,
    free: *const fn (*anyopaque, []u8) void,
    resize: ?*const fn (*anyopaque, []u8, usize) Err![]u8 = null,
};

private: *anyopaque,
vtable: *const VTable,

const Self: type = @This();

/// * init Self
pub noinline fn init(self: *const Self) Err!void {
    return self.vtable.init(self.private);
}

/// * deinit Self
pub noinline fn deinit(self: *const Self) Err!void {
    return self.vtable.deinit(self.private);
}

/// * alloc a slice of type []T containing "n" elements
pub noinline fn alloc(self: *const Self, comptime T: type, n: usize) Err![]T {
    return @ptrCast(@alignCast(try @call(.always_inline, self.vtable.alloc, .{ self.private, n })));
}

/// * free a slice
pub noinline fn free(self: *const Self, ptr: anytype) void {
    if (!comptime meta.isSlice(@TypeOf(ptr)))
        @compileError("\"fn free()\" expect a slice!");

    @call(.always_inline, self.vtable.free, .{ self.private, @as([]u8, @ptrCast(@alignCast(ptr))) });
}

/// * alloc a single element pointer
pub noinline fn create(self: *const Self, comptime T: type) Err!*T {
    return @ptrCast(@alignCast(try @call(.always_inline, self.vtable.alloc, .{ self.private, @sizeOf(T) })));
}

/// * free a single element pointer
pub noinline fn destroy(self: *const Self, ptr: anytype) void {
    if (!comptime meta.isSinglePointer(@TypeOf(ptr)))
        @compileError("\"fn destroy()\" expect a one element pointer!");

    @call(.always_inline, self.vtable.free, .{ self.private, @as([]u8, @ptrCast(ptr)) });
}

/// * readjusts the size of a slice
/// * depending on the implementation, you can allocate a new slice and copy the old data, or just expand the old slice
pub noinline fn resize(self: *const Self, ptr: anytype, new_size: usize) Err![]meta.Child(@TypeOf(ptr)) {
    if (!comptime meta.isSlice(@TypeOf(ptr)))
        @compileError("\"fn resize()\" expect a slice!");

    return if (self.vtable.resize == null) Err.InvalidOperation else @ptrCast(@alignCast(@call(.always_inline, self.vtable.resize.?, .{ self.private, ptr, new_size })));
}
