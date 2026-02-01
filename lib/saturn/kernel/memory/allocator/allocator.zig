// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: allocator.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub const Err_T: type = error {
    InitFailed,
    IndexOutBounds,
    WithoutMemory,
    AlreadyInitialized,
    NoNInitialized,
    InternalError,
};

pub const VTable_T: type = struct {
    alloc: *const fn(alloc_self: *anyopaque, len: usize) Err_T![]u8,
    free: *const fn(alloc_self: *anyopaque, ptr: []u8) Err_T!void,
    init: *const fn(alloc_self: *anyopaque) Err_T!void,
    deinit: *const fn(alloc_self: *anyopaque) Err_T!void,
    is_initialized: *const fn(alloc_self: *anyopaque) bool,
};

pub const Allocator_T: type = struct {
    vtable: *const VTable_T,
    private: *anyopaque,

    pub fn alloc(self: Allocator_T, comptime T: type, num: usize) Err_T![]T {
        return @alignCast(@ptrCast(
            (try self.vtable.alloc(self.private, num))[0..(@sizeOf(T) * num)]
        ));
    }

    pub fn free(self: Allocator_T, ptr: anytype) Err_T!void {
        const ptr_size, const ptr_child = comptime sw: switch(@typeInfo(@TypeOf(ptr))) {
            .pointer => |ptr_info| {
                if(ptr_info.size == .c or ptr_info.size == .many)
                    continue :sw @typeInfo(void);
                break :sw .{
                    ptr_info.size,
                    ptr_info.child
                };
            },
            else => @compileError("expect slice or single pointer to free. Found \"" ++ @typeName(@TypeOf(ptr)) ++ "\""),
        };
        const slice = ptr[0..@sizeOf(ptr_child) * (
            if(comptime ptr_size == .one) 1 else ptr.len
        )];
        return self.vtable.free(self.private, slice);
    }

    pub fn init(self: Allocator_T) Err_T!void {
        return self.vtable.init(self.private);
    }

    pub fn deinit(self: Allocator_T) void {
        return self.vtable.deinit(self.private);
    }

    pub fn is_initialized(self: Allocator_T) bool {
        return self.vtable.is_initialized(self.private);
    }
};
