// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub const Err_T: type = error {
    WithoutMemory,
    InternalError,
    ResizeImpossible,
    NoInitilized,
    InitFailed,
    InvalidOperation,
};

pub const VTable_T: type = struct {
    init: *const fn(*anyopaque) Err_T!void,
    deinit: *const fn(*anyopaque) Err_T!void,
    alloc: *const fn(*anyopaque, usize) Err_T![]u8,
    free: *const fn(*anyopaque, []u8) void,
    resize: ?*const fn(*anyopaque, []u8, usize) Err_T![]u8 = null,
};

pub const Allocator_T: type = struct {
    private: *anyopaque,
    vtable: *const VTable_T,

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

    /// * init allocator
    pub noinline fn init(self: *const Allocator_T) Err_T!void {
        return self.vtable.init(self.private);
    }

    /// * deinit allocator
    pub noinline fn deinit(self: *const Allocator_T) Err_T!void {
        return self.vtable.deinit(self.private);
    }

    /// * alloc a slice of type []T containing "n" elements
    pub noinline fn alloc(self: *const Allocator_T, comptime T: type, n: usize) Err_T![]T {
        return @alignCast(@ptrCast(
            try @call(.always_inline, self.vtable.alloc, .{ self.private, n }))
        );
    }

    /// * free a slice
    pub noinline fn free(self: *const Allocator_T, ptr: anytype) void {
        if(!comptime is_slice(@TypeOf(ptr)))
            @compileError("\"fn free()\" expect a slice!");

        @call(.always_inline, self.vtable.free, .{ self.private, @as([]u8, @alignCast(@ptrCast(ptr))) });
    }

    /// * alloc a single element pointer
    pub noinline fn create(self: *const Allocator_T, comptime T: type) Err_T!*T {
        return @alignCast(@ptrCast(
<<<<<<< HEAD
            try @call(.always_inline, self.vtable.alloc, .{ self.private, @sizeOf(T) }))
=======
            try @call(.never_inline, self.vtable.alloc, .{ self.private, @sizeOf(T) }))
>>>>>>> 065db47 (feat: new sba)
        );
    }

    /// * free a single element pointer
    pub noinline fn destroy(self: *const Allocator_T, ptr: anytype) void {
        if(!comptime is_one(@TypeOf(ptr)))
            @compileError("\"fn destroy()\" expect a one element pointer!");
<<<<<<< HEAD

        @call(.always_inline, self.vtable.free, .{ self.private, @as([]u8, @ptrCast(ptr)) });
=======
        @call(.never_inline, self.vtable.free, .{ self.private, @as([]u8, @ptrCast(ptr)) });
>>>>>>> 065db47 (feat: new sba)
    }

    /// * readjusts the size of a slice
    /// * depending on the implementation, you can allocate a new slice and copy the old data, or just expand the old slice
    pub noinline fn resize(self: *const Allocator_T, ptr: anytype, new_size: usize) Err_T![]extract_child(@TypeOf(ptr)) {
        if(!comptime is_slice(@TypeOf(ptr)))
            @compileError("\"fn resize()\" expect a slice!");

        return if(self.vtable.resize == null) Err_T.InvalidOperation else @alignCast(@ptrCast(
            @call(.always_inline, self.vtable.resize.?, .{ self.private, ptr, new_size })
        ));
    }
};
