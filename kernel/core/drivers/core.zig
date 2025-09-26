// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Allocator: type = @import("allocator.zig");
const Extern: type = struct {
    pub const Driver_T: type = @import("types.zig").Driver_T;
    pub const DriverErr_T: type = @import("types.zig").DriverErr_T;
    pub const Ops_T: type = @import("types.zig").Ops_T;
    pub const OpsErr_T: type = @import("types.zig").OpsErr_T;
    pub const MajorNum_T: type = @import("types.zig").MajorNum_T;
    pub const MinorNum_T: type = @import("types.zig").MinorNum_T;
};
const Internal: type = struct {
    pub const MajorLevel0: type = @import("types.zig").MajorLevel0;
    pub const MajorLevel1: type = @import("types.zig").MajorLevel1;
    pub const MajorLevel2: type = @import("types.zig").MajorLevel2;
    pub const Steps: type = enum {
        Level0O,
        Level1B,
        Level1O,
        Level2B,
        Level2O,
    };
};

// A ideia de aplicar esse algoritmo e justamente pensando em
// otimizar acesso a um major, que deve ser extremamente
// eficiente, mas tambem precisamos permitir um tamanho dinamico
//
// Aqui temos um add e um del mais robusto, mas temos uma busca
// por major extremamente veloz, com praticamente 0 overhead, o
// maximo de overhead que vamos ter e ver se o caminho e valido
// mas todos os acessos a busca e sempre certeiro

var majorsLevels: Internal.MajorLevel0 = .{
    .base = .{
        null
    } ** 16,
    .map = 0,
};

fn majorPartBits(major: Extern.MajorNum_T) struct { u4, u2, u2 } {
    return .{
        @intCast((major >> 4) & 0x0F),
        @intCast((major >> 2) & 0x03),
        @intCast(major & 0x03),
    };
}

fn valid_path(major: Extern.MajorNum_T) struct { ?Internal.Steps, bool } {
    const high, const mid, const low = @call(.always_inline, &majorPartBits, .{
        major
    });
    return if(majorsLevels.base[high] == null) .{ Internal.Steps.Level0O, false } else r: {
        const Castings = [_]type {
            Internal.MajorLevel1,
            Internal.MajorLevel2,
        };
        const base_offset = [_]u2 {
            mid,
            low,
        };
        var ptr: *anyopaque = &majorsLevels.base[high].?.*;
        inline for(0..Castings.len) |i| {
            const casting: *Castings[i] = @alignCast(@ptrCast(ptr));
            if(casting.base == null) {
                break :r .{
                    @as(Internal.Steps, @enumFromInt(i + i + 1)),
                    false,
                };
            }
            if(casting.base.?[base_offset[i]] == null) {
                break :r .{
                    @as(Internal.Steps, @enumFromInt(i + i + 2)),
                    false,
                };
            }
            ptr = casting.base.?[base_offset[i]].?;
        }
        break :r .{
            null,
            true,
        };
    };
}

pub fn add(driver: *const Extern.Driver_T) Extern.DriverErr_T!void {
    const broken_level, const result = @call(.never_inline, &valid_path, .{
        driver.major
    });
    return if(result) Extern.DriverErr_T.MajorCollision else r: {
        const high, const mid, const low = @call(.always_inline, &majorPartBits, .{
            driver.major
        });
        sw: switch(broken_level.?) {
            .Level0O => {
                majorsLevels.base[high] = @call(.never_inline, &Internal.MajorLevel1.Allocator.Level.alloc, .{}) catch |err| switch(err) {
                    Internal.MajorLevel1.Allocator.Level.AllocatorErr_T.OutOfMemory => break :r Extern.DriverErr_T.OutMajor,
                    else => {
                        break :r Extern.DriverErr_T.InternalError;
                    },
                };
                majorsLevels.map |= @as(@TypeOf(majorsLevels.map), @intCast(0x01)) << high;
                continue :sw .Level1B;
            },

            .Level1B => {
                majorsLevels.base[high].?.base = @call(.never_inline, &Internal.MajorLevel1.Allocator.Base.alloc, .{}) catch |err| switch(err) {
                    Internal.MajorLevel1.Allocator.Base.AllocatorErr_T.OutOfMemory => break :r Extern.DriverErr_T.OutMajor,
                    else => {
                        break :r Extern.DriverErr_T.InternalError;
                    },
                }; for(0..majorsLevels.base[high].?.base.?.len) |i| {
                    majorsLevels.base[high].?.base.?[i] = null;
                } continue :sw .Level1O;
            },

            .Level1O => {
                majorsLevels.base[high].?.base.?[mid] = @call(.never_inline, &Internal.MajorLevel2.Allocator.Level.alloc, .{}) catch |err| switch(err) {
                    Internal.MajorLevel2.Allocator.Level.AllocatorErr_T.OutOfMemory => break :r Extern.DriverErr_T.OutMajor,
                    else => {
                        break :r Extern.DriverErr_T.InternalError;
                    },
                };
                majorsLevels.base[high].?.map |= @as(@TypeOf(majorsLevels.base[high].?.map), @intCast(0x01)) << mid;
                continue :sw .Level2B;
            },

            .Level2B => {
                majorsLevels.base[high].?.base.?[mid].?.base = @call(.never_inline, &Internal.MajorLevel2.Allocator.Base.alloc, .{})
                catch |err| switch(err) {
                    Internal.MajorLevel2.Allocator.Base.AllocatorErr_T.OutOfMemory => break :r Extern.DriverErr_T.OutMajor,
                    else => {
                        break :r Extern.DriverErr_T.InternalError;
                    },
                }; for(0..majorsLevels.base[high].?.base.?[mid].?.base.?.len) |i| {
                    majorsLevels.base[high].?.base.?[mid].?.base.?[i] = null;
                } continue :sw .Level2O;
            },

            .Level2O => {
                majorsLevels.base[high].?.base.?[mid].?.base.?[low] = @call(.never_inline, &Allocator.alloc, .{}) catch |err| switch(err) {
                    Allocator.AllocatorErr_T.OutOfMemory => break :r Extern.DriverErr_T.OutMajor,
                    else => {
                        break :r Extern.DriverErr_T.InternalError;
                    },
                };
                majorsLevels.base[high].?.base.?[mid].?.map |= @as(@TypeOf(majorsLevels.base[high].?.base.?[mid].?.map), @intCast(0x01)) << low;
            },
        }
        majorsLevels.base[high].?.base.?[mid].?.base.?[low].?.* = driver.*;
        break :r {};
    };
}

pub fn del(major: Extern.MajorNum_T) Extern.DriverErr_T!void {
    if(!@import("builtin").is_test)
        if(comptime @import("root").modules.countModOfType(.driver) == 0) return;
    return if(!@call(.never_inline, &valid_path, .{
        major
    }).@"1") Extern.DriverErr_T.DoubleFree else r: {
        const high, const mid, const low = @call(.always_inline, &majorPartBits, .{
            major
        });
        sw: switch(Internal.Steps.Level2O) {
            .Level2O => {
                @call(.never_inline, &Allocator.free, .{
                    majorsLevels.base[high].?.base.?[mid].?.base.?[low].?
                }) catch break :r Extern.DriverErr_T.InternalError;
                majorsLevels.base[high].?.base.?[mid].?.base.?[low] = null;
                majorsLevels.base[high].?.base.?[mid].?.map &= ~(@as(@TypeOf(majorsLevels.base[high].?.base.?[mid].?.map), 0x01) << low);
                continue :sw .Level2B;
            },

            .Level2B => {
                if(majorsLevels.base[high].?.base.?[mid].?.map != 0) break :sw {};
                @call(.never_inline, &Internal.MajorLevel2.Allocator.Base.free, .{
                    majorsLevels.base[high].?.base.?[mid].?.base
                }) catch break :r Extern.DriverErr_T.InternalError;
                majorsLevels.base[high].?.base.?[mid].?.base = null;
                continue :sw .Level1O;
            },

            .Level1O => {
                @call(.never_inline, &Internal.MajorLevel2.Allocator.Level.free, .{
                    majorsLevels.base[high].?.base.?[mid]
                }) catch break :r Extern.DriverErr_T.InternalError;
                majorsLevels.base[high].?.base.?[mid] = null;
                majorsLevels.base[high].?.map &= ~(@as(@TypeOf(majorsLevels.base[high].?.map), 0x01) << mid);
                continue :sw .Level1B;
            },

            .Level1B => {
                if(majorsLevels.base[high].?.map != 0) break :sw {};
                @call(.never_inline, &Internal.MajorLevel1.Allocator.Base.free, .{
                    majorsLevels.base[high].?.base
                }) catch break :r Extern.DriverErr_T.InternalError;
                majorsLevels.base[high].?.base = null; continue :sw .Level0O;
            },

            .Level0O => {
                @call(.never_inline, &Internal.MajorLevel1.Allocator.Level.free, .{
                    majorsLevels.base[high]
                }) catch break :r Extern.DriverErr_T.InternalError;
                majorsLevels.base[high] = null;
                majorsLevels.map &= ~(@as(@TypeOf(majorsLevels.map), 0x01) << high);
            },
        }
        break :r {};
    };
}

pub fn search(major: Extern.MajorNum_T) Extern.DriverErr_T!*Extern.Driver_T {
    const high, const mid, const low = @call(.always_inline, &majorPartBits, .{
        major
    });
    return if(!@call(.always_inline, &valid_path, .{
        major
    }).@"1") Extern.DriverErr_T.NonFound else majorsLevels.base[high].?.base.?[mid].?.base.?[low].?;
}

// == Saturn Internal Major Test ==

const TestErr_T: type = error {
    UndefinedAction,
    UnreachableCode,
    MemoryLeakDetected,
};
const MaxMajorNum: Extern.MajorNum_T = 64;
var majorTester: Extern.Driver_T = .{
    .major = 0,
    .ops = .{
        .open = null,
        .close = null,
        .read = &struct {
            pub fn read(_: Extern.MinorNum_T, _: usize) Extern.DriverErr_T![]u8 {
                return @constCast("Hello, World!");
            }
        }.read,
        .write = &struct {
            pub fn write(_: Extern.MinorNum_T, _: []const u8) Extern.DriverErr_T!void {

            }
        }.write,
        .minor = &struct {
            pub fn minor(_: Extern.MinorNum_T) Extern.DriverErr_T!void {

            }
        }.minor,
        .ioctrl = &struct {
            fn minor(_: Extern.MinorNum_T, _: usize, _: usize) Extern.OpsErr_T!usize {
                return 0xAABB;
            }
        }.minor,
    }
};

test "Major Recursive Add" {
    majorTester.major = 0;
    for(0..MaxMajorNum) |_| {
        try add(&majorTester);
        add(&majorTester) catch |err| switch(err) {
            Extern.DriverErr_T.MajorCollision => {},
            else => return TestErr_T.UnreachableCode,
        };
        if((try search(majorTester.major)).major != majorTester.major) {
            return TestErr_T.UndefinedAction;
        }
        majorTester.major += 1;
    }
}

test "Major Recursive Del" {
    majorTester.major = 0;
    for(0..MaxMajorNum) |_| {
        try del(majorTester.major);
        del(majorTester.major) catch |err| switch(err) {
            Extern.DriverErr_T.DoubleFree => {},
            else => return TestErr_T.UnreachableCode,
        };
        try add(&majorTester);
        if((try search(majorTester.major)).major != majorTester.major) {
            return TestErr_T.UndefinedAction;
        }
        try del(majorTester.major);
        del(majorTester.major) catch |err| switch(err) {
            Extern.DriverErr_T.DoubleFree => {},
            else => return TestErr_T.UnreachableCode,
        };
        _ = search(majorTester.major) catch |err| switch(err) {
            Extern.DriverErr_T.NonFound => {},
            else => return TestErr_T.UnreachableCode,
        };
        majorTester.major += 1;
    }
}

test "Major Memory Leak Detect" {

}

test "Major Search With 0 Major" {
    majorTester.major = 0;
    for(0..MaxMajorNum) |_| {
        _ = search(majorTester.major) catch |err| switch(err) {
            Extern.DriverErr_T.NonFound => {
                majorTester.major += 1; continue;
            },
            else => return TestErr_T.UndefinedAction,
        };
        return TestErr_T.UnreachableCode;
    }
}

test "Major Recursive Add Again" {
    majorTester.major = 0;
    for(0..MaxMajorNum) |_| {
        try add(&majorTester);
        add(&majorTester) catch |err| switch(err) {
            Extern.DriverErr_T.MajorCollision => {},
            else => return TestErr_T.UnreachableCode,
        };
        if((try search(majorTester.major)).major != majorTester.major) {
            return TestErr_T.UndefinedAction;
        }
        majorTester.major += 1;
    }
}

test "Major Memory Leak Detect" {
    for(0..MaxMajorNum) |i| {
        try del(@intCast(i));
    }
    const Allocators = [_]type {
        Allocator,
        Internal.MajorLevel1.Allocator.Base,
        Internal.MajorLevel1.Allocator.Level,
        Internal.MajorLevel2.Allocator.Base,
        Internal.MajorLevel2.Allocator.Level,
    };
    inline for(Allocators) |allocator| {
        if(allocator.haveAllocs()) {
            const std: type = @import("std");
            std.debug.print("Memory Leak On Allocator: {s}\n", .{
                @typeName(allocator)
            });
            return TestErr_T.MemoryLeakDetected;
        }
    }
}

