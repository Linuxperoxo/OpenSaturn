// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: radix.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Driver_T: type = @import("types.zig").Driver_T;

pub const Level1: type = struct {
    line: [16]?*Level2,
    map: u16,
};

pub const Level2: type = struct {
    line: ?*[4]?*Level3,
    map: u4,
};

pub const Level3: type = struct {
    line: ?*[4]?*Driver_T,
    map: u4,
};

pub const Allocator: type = struct {
    const SOA: type = @import("root").memory.SOA;
    const Allocator_T: type = SOA.buildObjAllocator(
        [4]?*anyopaque,
        128,
        .huge,
        null,
        null,
        null,
        .in16,
        .optimized
        .PrioritizeHits,
        .Insistent,
    );
    pub const AllocatorErr_T: type = Allocator_T.err_T;

    var allocator = r: {
        var AllocTmp: Allocator_T = undefined;
        @call(.compile_time, Allocator_T.init, .{
            &AllocTmp
        });
        break :r AllocTmp;
    };

    fn verify(T: type) void {
        comptime {
            if(T != Level2 or T != Level3) {
                @compileError(
                    "radix allocator expect types " ++
                    @typeName(Level2) ++
                    " or " ++
                    @typeName(Level3)
                );
            }
        }
    }

    pub fn alloc(T: type) AllocatorErr_T!*T {
        @call(.compile_time, verify, .{
            T
        });
        return @alignCast(@ptrCast(@call(.always_inline, Allocator_T.alloc, .{
            &allocator
        })));
    }

    pub fn free(obj: anytype) AllocatorErr_T!void {
        comptime {
            switch(@typeInfo(@TypeOf(obj))) {
                .pointer => |info| {
                    @call(.compile_time, verify, .{
                        info.child
                    });
                },
                else => @compileError(
                    "radix free expect pointer of types " ++
                    @typeName(Level2) ++
                    " or " ++
                    @typeName(Level3)
                ),
            }
        }
        return @call(.always_inline, Allocator_T.free, .{
            &allocator, ((@intFromPtr(obj) - @intFromPtr(&Allocator.objs[0])) / @sizeOf([4]?*anyopaque)),
        });
    }
};
