// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub const Allocator_T: type = struct {
    private: *anyopaque,
    vtable: *const Vtable_T,

    pub const Vtable_T: type = struct {
        alloc: *const fn(*anyopaque, N: usize) anyerror![]u8,
        free: *const fn(*anyopaque, []u8) void,
        create: *const fn(*anyopaque, []u8) anyerror![]u8,
        destroy: *const fn(*anyopaque, []u8) void,
        resize: *const fn(*anyopaque, []u8, usize) anyerror![]u8,
    };

    fn is_slice(T: type) bool {
        return switch(@typeInfo(T)) {
            .pointer => |pointer|
                (pointer.size == .slice),
            else => false,
        };
    }

    fn is_one(T: type) bool {
        return switch(@typeInfo(T)) {
            .pointer => |pointer|
                (pointer.size == .one),
            else => false,
        };
    }

    fn extract_child(T: type) type {
        return if(comptime is_slice(T)) @typeInfo(T).pointer.child else
            T;
    }

    /// * alloc a slice of type []T containing "n" elements
    pub noinline fn alloc(self: *const Allocator_T, comptime T: type, n: usize) anyerror![]T {
        return @alignCast(@ptrCast(
            try @call(.never_inline, self.vtable.alloc, .{ self.private, n }))
        );
    }

    /// * free a slice
    pub noinline fn free(self: *const Allocator_T, ptr: anytype) void {
        if(!comptime is_slice(@TypeOf(ptr)))
            @compileError("\"fn free()\" expect a slice!");
        @call(.never_inline, self.vtable.free, .{ self.private, @as([]u8, @alignCast(@ptrCast(ptr))) });
    }

    /// * alloc a single element pointer
    pub noinline fn create(self: *const Allocator_T, comptime T: type) anyerror!*T {
        return @alignCast(@ptrCast(
            try @call(.never_inline, self.vtable.create, .{ self.private, T }))
        );
    }

    /// * free a single element pointer
    pub noinline fn destroy(self: *const Allocator_T, ptr: anytype) void {
        if(!comptime is_one(@TypeOf(ptr)))
            @compileError("\"fn destroy()\" expect a one element pointer!");
        @call(.never_inline, self.vtable.destroy, .{ self.private, ptr });
    }

    /// * readjusts the size of a slice
    /// * depending on the implementation, you can allocate a new slice and copy the old data, or just expand the old slice
    pub noinline fn resize(self: *const Allocator_T, ptr: anytype, new_size: usize) anyerror![]extract_child(@TypeOf(ptr)) {
        if(!comptime is_slice(@TypeOf(ptr)))
            @compileError("\"fn resize()\" expect a slice!");
        return @alignCast(@ptrCast(
            @call(.never_inline, self.vtable.resize, .{ self.private, ptr, new_size })
        ));
    }
};
