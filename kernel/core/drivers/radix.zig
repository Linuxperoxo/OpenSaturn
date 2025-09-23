// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: radix.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const SOA: type = @import("memory.zig").SOA;
const Driver_T: type = @import("types.zig").Driver_T;

pub const Level0_T: type = struct {
    line: [16]?*Level1_T,
    map: u16,
};

pub const Level1_T: type = struct {
    line: ?*Level1Line_T,
    map: u4,

    const Level1Line_T: type = [4]?*Level2_T;
    const Self: type = @This();

    // Level1 Allocator
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

    // Level1 Line Allocator
    pub const Line: type = struct {
        pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
        const SOAAllocator_T: type = SOA.buildObjAllocator(
            Self.Level1Line_T,
            false,
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

pub const Level2_T: type = struct {
    line: ?*Level2Line_T,
    map: u4,

    const Level2Line_T: type = [4]?*Driver_T;
    const Self: type = @This();

    // Level2 Allocator
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

    // Level2 Line Allocator
    pub const Line: type = struct {
        pub const AllocatorErr_T: type = SOAAllocator_T.err_T;
        const SOAAllocator_T: type = SOA.buildObjAllocator(
            Self.Level2Line_T,
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
