// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const SOA: type = @import("memory.zig").SOA;

pub const MajorNum_T: type = if(@import("builtin").is_test) u6 else @import("root").core.drivers.types.MajorNum_T;
pub const MinorNum_T: type = u8;

pub const Dev_T: type = struct {
    major: MajorNum_T,
    minor: MinorNum_T,
    type: enum {
        char,
        block
    },
};

pub const DevErr_T: type = error {
    MinorInodeCollision,
    Locked,
    OutOfMinor,
    InternalError,
    MinorDoubleFree,
    NonMinor,
    MajorReturnError,
};

pub const DevicesInodeLevel0: type = struct {
    pub const baseSize: comptime_int = (@bitSizeOf(MinorNum_T) / 2) * (@bitSizeOf(MinorNum_T) / 2);
    pub const Base_T: type = [baseSize]?*DevicesInodeLevel1;
    base: Base_T,
    map: switch(baseSize) {
        8 => u8,
        16 => u16,
        else => @compileError(
            "representation in bits for minor can not pass from u16"
        ),
    } = 0,
};

pub const DevicesInodeLevel1: type = struct {
    pub const baseSize: comptime_int = (@bitSizeOf(MinorNum_T) / 4) * (@bitSizeOf(MinorNum_T) / 4);
    pub const Base_T: type = [baseSize]?*DevicesInodeLevel2;
    base: ?*Base_T,
    map: switch(baseSize) {
        4 => u4,
        8 => u8,
        else => unreachable,
    },

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
                return @call(.always_inline, &SOAAllocator_T.alloc, .{
                    &allocator
                });
            }

            pub fn free(obj: ?*SOAAllocator_T.Options.Type) AllocatorErr_T!void {
                return if(obj == null) {} else @call(.always_inline, &SOAAllocator_T.free, .{
                    &allocator, obj.?
                });
            }
        };

        pub const Base: type = struct {
            pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
            const SOAAllocator_T: type = SOA.buildObjAllocator(
                Self.Base_T,
                false,
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
                return @call(.always_inline, &SOAAllocator_T.alloc, .{
                    &allocator
                });
            }

            pub fn free(obj: ?*SOAAllocator_T.Options.Type) AllocatorErr_T!void {
                return if(obj == null) {} else @call(.always_inline, &SOAAllocator_T.free, .{
                    &allocator, obj.?
                });
            }
        };
    };
};

pub const DevicesInodeLevel2: type = struct {
    pub const baseSize: comptime_int = (@bitSizeOf(MinorNum_T) / 4) * (@bitSizeOf(MinorNum_T) / 4);
    pub const Base_T: type = [baseSize]?*Dev_T;
    base: ?*Base_T,
    map: switch(baseSize) {
        4 => u4,
        8 => u8,
        else => unreachable,
    },

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
                return @call(.always_inline, &SOAAllocator_T.alloc, .{
                    &allocator
                });
            }

            pub fn free(obj: ?*SOAAllocator_T.Options.Type) AllocatorErr_T!void {
                return if(obj == null) {} else @call(.always_inline, &SOAAllocator_T.free, .{
                    &allocator, obj.?
                });
            }
        };

        pub const Base: type = struct {
            pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
            const SOAAllocator_T: type = SOA.buildObjAllocator(
                Self.Base_T,
                false,
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
                return @call(.always_inline, &SOAAllocator_T.alloc, .{
                    &allocator
                }) catch {
                                    const std: type = @import("std");
                std.debug.print("{d}\n", .{
                    allocator.allocs
                });
                while(true) {}

                };
            }

            pub fn free(obj: ?*SOAAllocator_T.Options.Type) AllocatorErr_T!void {
                return if(obj == null) {} else @call(.always_inline, &SOAAllocator_T.free, .{
                    &allocator, obj.?
                });
            }
        };
    };
};

