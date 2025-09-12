// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: radix.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Driver_T: type = @import("types.zig").Driver_T;

pub const Level0_T: type = struct {
    line: [16]?*Level1_T,
    map: u16,
};

pub const Level1_T: type = struct {
    pub const Level1Line_T: type = ?*[4]?*Level2_T;
    line: Level1Line_T,
    map: u4,
};

pub const Level2_T: type = struct {
    pub const Level2Line_T: type = ?*[4]?*Driver_T;
    line: Level2Line_T,
    map: u4,
};

pub const Allocators: type = struct {
    pub const Lines: type = struct {
        const SOA: type = @import("root").memory.SOA;
        const Allocator_T: type = SOA.buildObjAllocator(
            [4]?*anyopaque,
            64,
            .huge,
            null,
            null,
            null,
            .in8,
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

        pub fn alloc() AllocatorErr_T!*[4]?*anyopaque {
            return @alignCast(@ptrCast(@call(.always_inline, Allocator_T.alloc, .{
                &allocator
            })));
        }

        pub fn free(obj: anytype) AllocatorErr_T!void {
            return @call(.always_inline, Allocator_T.free, .{
                &allocator, ((@intFromPtr(obj) - @intFromPtr(&allocator.objs[0])) / @sizeOf([4]?*anyopaque)),
            });
        }
    };

    pub const Levels: type = struct {
        const SOA: type = @import("root").memory.SOA;
        const Allocator_T: type = SOA.buildObjAllocator(
            struct {
                ?*[4]?*anyopaque,
                u4,
            },
            64,
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
                if(T != Level1_T or T != Level2_T) {
                    @compileError(
                        "radix allocator expect types " ++
                        @typeName(Level1_T) ++
                        " or " ++
                        @typeName(Level2_T)
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
                        @typeName(Level1_T) ++
                        " or " ++
                        @typeName(Level2_T)
                    ),
                }
            }
            return @call(.always_inline, Allocator_T.free, .{
                &allocator, ((@intFromPtr(obj) - @intFromPtr(&allocator.objs[0])) / @sizeOf(struct {
                    ?*[4]?*anyopaque,
                    u4,
                })),
            });
        }
    };
};
