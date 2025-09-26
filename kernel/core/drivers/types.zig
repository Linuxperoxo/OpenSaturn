// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const MajorNum_T: type = u8;
pub const MinorNum_T: type = if(@import("builtin").is_test) u8 else @import("root").interfaces.devices.MinorNum_T;

pub const OpsErr_T: type = error {
    NoCMD,
    Failed,
    Unreachable,
};

pub const DriverErr_T: type = error {
    InternalError,
    Blocked,
    NonFound,
    MajorCollision,
    OutMajor,
    DoubleFree,
    MinorCollision,
    UndefinedMajor,
    UndefinedMinor,
    Unreachable,
};

pub const Ops_T: type = struct {
    read: *const fn(minor: MinorNum_T, offset: usize) DriverErr_T![]u8,
    write: *const fn(minor: MinorNum_T, data: []const u8) DriverErr_T!void,
    ioctrl: *const fn(minor: MinorNum_T, command: usize, data: usize) OpsErr_T!usize,
    minor: *const fn(minor: MinorNum_T) DriverErr_T!void,
    open: ?*const fn(minor: MinorNum_T) DriverErr_T!void,
    close: ?*const fn(minor: MinorNum_T) DriverErr_T!void,
};

pub const Driver_T: type = struct {
    major: MajorNum_T,
    ops: Ops_T,
};

pub const MajorLevel0: type = struct {
    pub const baseSize: comptime_int = (@bitSizeOf(MinorNum_T) / 2) * (@bitSizeOf(MinorNum_T) / 2);
    pub const Base_T: type = [baseSize]?*MajorLevel1;
    base: Base_T,
    map: switch(baseSize) {
        16 => u16,
        else => @compileError(
            ""
        ),
    },
};

pub const MajorLevel1: type = struct {
    pub const baseSize: comptime_int = (@bitSizeOf(MinorNum_T) / 4) * (@bitSizeOf(MinorNum_T) / 4);
    pub const Base_T: type = [baseSize]?*MajorLevel2;
    base: ?*Base_T,
    map: switch(baseSize) {
        4 => u4,
        else => @compileError(
            ""
        ),
    },

    const SOA: type = @import("memory.zig").SOA;
    const Self: type = @This();
    pub const Allocator: type = struct {
        pub const Level: type = struct {
            pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
            const SOAAllocator_T: type = SOA.buildObjAllocator(
                Self,
                true,
                16,
                .{
                    .alignment = @enumFromInt(@sizeOf(usize)),
                    .range = .large,
                    .type = .linear,
                },
                .{}
            );

            var allocator: SOAAllocator_T = .{};

            pub fn alloc() AllocatorErr_T!*SOAAllocator_T.Options.Type {
                return @call(.never_inline, &SOAAllocator_T.alloc, .{
                    &allocator
                });
            }

            pub fn free(obj: ?*SOAAllocator_T.Options.Type) AllocatorErr_T!void {
                return if(obj == null) {} else @call(.never_inline, &SOAAllocator_T.free, .{
                    &allocator, obj.?
                });
            }

            pub fn haveAllocs() bool {
                return if(@import("builtin").is_test) allocator.allocs != 0 else @compileError(
                    "fn haveAllocs run in test mode only"
                );
            }
        };

        pub const Base: type = struct {
            pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
            const SOAAllocator_T: type = SOA.buildObjAllocator(
                Self.Base_T,
                true,
                16,
                .{
                    .alignment = @enumFromInt(@sizeOf(usize)),
                    .range = .large,
                    .type = .linear,
                },
                .{}
            );

            var allocator: SOAAllocator_T = .{};

            pub fn alloc() AllocatorErr_T!*SOAAllocator_T.Options.Type {
                return @call(.never_inline, &SOAAllocator_T.alloc, .{
                    &allocator
                });
            }

            pub fn free(obj: ?*SOAAllocator_T.Options.Type) AllocatorErr_T!void {
                return if(obj == null) {} else @call(.never_inline, &SOAAllocator_T.free, .{
                    &allocator, obj.?
                });
            }

            pub fn haveAllocs() bool {
                return if(@import("builtin").is_test) allocator.allocs != 0 else @compileError(
                    "fn haveAllocs run in test mode only"
                );
            }
        };
    };
};

pub const MajorLevel2: type = struct {
    pub const baseSize: comptime_int = (@bitSizeOf(MinorNum_T) / 4) * (@bitSizeOf(MinorNum_T) / 4);
    pub const Base_T: type = [baseSize]?*Driver_T;
    base: ?*Base_T,
    map: switch(baseSize) {
        4 => u4,
        else => @compileError(
            ""
        ),
    },

    const SOA: type = @import("memory.zig").SOA;
    const Self: type = @This();
    pub const Allocator: type = struct {
        pub const Level: type = struct {
            pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
            const SOAAllocator_T: type = SOA.buildObjAllocator(
                Self,
                true,
                64,
                .{
                    .alignment = @enumFromInt(@sizeOf(usize)),
                    .range = .large,
                    .type = .linear,
                },
                .{}
            );

            var allocator: SOAAllocator_T = .{};

            pub fn alloc() AllocatorErr_T!*SOAAllocator_T.Options.Type {
                return @call(.never_inline, &SOAAllocator_T.alloc, .{
                    &allocator
                });
            }

            pub fn free(obj: ?*SOAAllocator_T.Options.Type) AllocatorErr_T!void {
                return if(obj == null) {} else @call(.never_inline, &SOAAllocator_T.free, .{
                    &allocator, obj.?
                });
            }

            pub fn haveAllocs() bool {
                return if(@import("builtin").is_test) allocator.allocs != 0 else @compileError(
                    "fn haveAllocs run in test mode only"
                );
            }
        };

        pub const Base: type = struct {
            pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
            const SOAAllocator_T: type = SOA.buildObjAllocator(
                Self.Base_T,
                true,
                64,
                .{
                    .alignment = @enumFromInt(@sizeOf(usize)),
                    .range = .large,
                    .type = .linear,
                },
                .{}
            );

            var allocator: SOAAllocator_T = .{};

            pub fn alloc() AllocatorErr_T!*SOAAllocator_T.Options.Type {
                return @call(.never_inline, &SOAAllocator_T.alloc, .{
                    &allocator
                });
            }

            pub fn free(obj: ?*SOAAllocator_T.Options.Type) AllocatorErr_T!void {
                return if(obj == null) {} else @call(.never_inline, &SOAAllocator_T.free, .{
                    &allocator, obj.?
                });
            }

            pub fn haveAllocs() bool {
                return if(@import("builtin").is_test) allocator.allocs != 0 else @compileError(
                    "fn haveAllocs run in test mode only"
                );
            }
        };
    };
};
