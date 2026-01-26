// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: vtable.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const AllocVTable_T: type = struct {
    fn_alloc: *const fn(self: *const @This(), bytes: usize) anyerror![]u8,
    fn_free: *const fn(self: *const @This(), ptr: []u8) anyerror!void,
    //fn_init: *const fn(self: *const @This()) anyerror!void,
    //fn_deinit: *const fn(self: *const @This()) void,
    //fn_is_initialized: *const fn(self: *const @This()) bool,
    private: *anyopaque,

    pub fn alloc(self: *const @This(), comptime T: type, N: usize) anyerror![]T {
        return @alignCast(@ptrCast(
            (self.fn_alloc(self, @sizeOf(T) * N))
        ));
    }

    pub fn free(self: *const @This(), ptr: anytype) anyerror!void {
        return self.fn_free(self, comptime sw: switch(@typeInfo(@TypeOf(ptr))) {
            .pointer => |p| {
                if(p.size == .c or p.size == .many)
                    continue :sw @typeInfo(void);
                break :sw @alignCast(@ptrCast(ptr[0..if(p.size == .one) 1 else ptr.len]));
            },

            else => @compileError("expect slice or single pointer to free. Found \"" ++ @typeName(@TypeOf(ptr)) ++ "\""),
        });
    }

    pub fn init(_: *const @This()) anyerror!void {
        //return self.fn_init();
    }

    pub fn deinit(_: *const @This()) void {
        //return self.fn_deinit();
    }

    pub fn is_initialized(_: *const @This()) bool {
        //return self.fn_is_initialized();
    }
};
