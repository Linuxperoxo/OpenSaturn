// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Radix: type = @import("radix.zig");
const Drivers: type = struct {
    const Driver_T: type = @import("types.zig").Driver_T;
    const DriverErr_T: type = @import("types.zig").DriverErr_T;
    const Ops_T: type = @import("types.zig").Ops_T;
    const OpsErr_T: type = @import("types.zig").OpsErr_T;
    const MajorNum_T: type = @import("types.zig").MajorNum_T;
    const MinorNum_T: type = @import("types.zig").MinorNum_T;
    const Allocator: type = @import("allocator.zig");
};

// A ideia de usar o radix e justamente pensando em
// otimizar acesso a um major, que deve ser extremamente
// eficiente, mas tambem precisamos permitir um tamanho dinamico
//
// Aqui temos um add e um del mais robusto, mas temos uma busca
// por major extremamente veloz, com praticamente 0 overhead, o
// maximo de overhead que vamos ter e ver se o caminho e valido
// mas todos os acessos a busca e sempre certeiro

var majorsLevels: Radix.Level0_T = .{
    .line = .{
        null
    } ** 16,
    .map = 0,
};

const Steps: type = enum {
    Level0O,
    Level1L,
    Level1O,
    Level2L,
    Level2O,
};

fn valid_path(high: u4, mid: u2, low: u2) bool {
    return (
        (majorsLevels.line[high] != null) and
        (majorsLevels.line[high].?.line != null) and
        (majorsLevels.line[high].?.line.?[mid] != null) and
        (majorsLevels.line[high].?.line.?[mid].?.line != null) and
        (majorsLevels.line[high].?.line.?[mid].?.line.?[low] != null)
    );
}

fn obsolete_path(high: u4, mid: u2) Steps {
    return r: {
        if(majorsLevels.line[high] == null) break :r .Level0O;
        if(majorsLevels.line[high].?.line == null) break :r .Level1L;
        if(majorsLevels.line[high].?.line.?[mid] == null) break :r .Level1O;
        if(majorsLevels.line[high].?.line.?[mid].?.line == null) break :r .Level2L;
        break :r Steps.Level2O;
    };
}

pub fn add(D: *const Drivers.Driver_T) Drivers.DriverErr_T!void {
    return if(@call(.never_inline, &valid_path, .{
        @as(u4, @intCast((D.major >> 4) & 0x0F)),
        @as(u2, @intCast((D.major >> 2) & 0x03)),
        @as(u2, @intCast(D.major & 0x03))
    })) Drivers.DriverErr_T.MajorCollision else r: {
        const high: u4 = @intCast((D.major >> 4) & 0x0F);
        const mid: u2 = @intCast((D.major >> 2) & 0x03);
        const low: u2 = @intCast(D.major & 0x03);
        sw: switch(@call(.always_inline, &obsolete_path, .{
            high, mid
        })) {
            .Level0O => {
                majorsLevels.line[high] = @call(.never_inline, &Radix.Level1_T.Level.alloc, .{}) catch |err| switch(err) {
                    Radix.Level1_T.Level.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
                    else => {
                        break :r Drivers.DriverErr_T.InternalError;
                    },
                };
                majorsLevels.map |= @as(u16, @intCast(0x01)) << high;
                continue :sw .Level1L;
            },

            .Level1L => {
                majorsLevels.line[high].?.line = @call(.never_inline, &Radix.Level1_T.Line.alloc, .{}) catch |err| switch(err) {
                    Radix.Level1_T.Line.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
                    else => {
                        break :r Drivers.DriverErr_T.InternalError;
                    },
                }; for(0..majorsLevels.line[high].?.line.?.len) |i| {
                    majorsLevels.line[high].?.line.?[i] = null;
                } continue :sw .Level1O;
            },

            .Level1O => {
                majorsLevels.line[high].?.line.?[mid] = @call(.never_inline, &Radix.Level2_T.Level.alloc, .{}) catch |err| switch(err) {
                    Radix.Level2_T.Level.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
                    else => {
                        break :r Drivers.DriverErr_T.InternalError;
                    },
                };
                majorsLevels.line[high].?.map |= @as(u4, @intCast(0x01)) << mid;
                continue :sw .Level2L;
            },

            .Level2L => {
                majorsLevels.line[high].?.line.?[mid].?.line = @call(.never_inline, &Radix.Level2_T.Line.alloc, .{})
                catch |err| switch(err) {
                    Radix.Level2_T.Line.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
                    else => {
                        break :r Drivers.DriverErr_T.InternalError;
                    },
                }; for(0..majorsLevels.line[high].?.line.?[mid].?.line.?.len) |i| {
                    majorsLevels.line[high].?.line.?[mid].?.line.?[i] = null;
                } continue :sw .Level2O;
            },

            .Level2O => {
                majorsLevels.line[high].?.line.?[mid].?.line.?[low] = @call(.never_inline, &Drivers.Allocator.alloc, .{}) catch |err| switch(err) {
                    Drivers.Allocator.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
                    else => {
                        break :r Drivers.DriverErr_T.InternalError;
                    },
                };
                majorsLevels.line[high].?.line.?[mid].?.map |= @as(u4, @intCast(0x01)) << low;
            },
        }
        majorsLevels.line[high].?.line.?[mid].?.line.?[low].?.* = D.*;
        break :r {};
    };
}

pub fn del(M: Drivers.MajorNum_T) Drivers.DriverErr_T!void {
    return if(!@call(.never_inline, &valid_path, .{
        @as(u4, @intCast((M >> 4) & 0x0F)),
        @as(u2, @intCast((M >> 2) & 0x03)),
        @as(u2, @intCast(M & 0x03))
    })) Drivers.DriverErr_T.DoubleFree else r: {
        const high: u4 = @intCast((M >> 4) & 0x0F);
        const mid: u2 = @intCast((M >> 2) & 0x03);
        const low: u2 = @intCast(M & 0x03);
        sw: switch(Steps.Level2O) {
            .Level2O => {
                @call(.never_inline, &Drivers.Allocator.free, .{
                    majorsLevels.line[high].?.line.?[mid].?.line.?[low].?
                }) catch {};
                majorsLevels.line[high].?.line.?[mid].?.line.?[low] = null;
                majorsLevels.line[high].?.line.?[mid].?.map &= ~(@as(u4, @intCast(0x01)) << low); continue :sw .Level2L;
            },

            .Level2L => {
                if(majorsLevels.line[high].?.line.?[mid].?.map != 0) break :sw {};
                @call(.never_inline, &Radix.Level2_T.Line.free, .{
                    majorsLevels.line[high].?.line.?[mid].?.line
                }) catch {};
                majorsLevels.line[high].?.line.?[mid].?.line = null; continue :sw .Level1O;
            },

            .Level1O => {
                @call(.never_inline, &Radix.Level2_T.Level.free, .{
                    majorsLevels.line[high].?.line.?[mid]
                }) catch {};
                majorsLevels.line[high].?.line.?[mid] = null;
                majorsLevels.line[high].?.map &= ~(@as(u4, @intCast(0x01)) << mid);
                continue :sw .Level1L;
            },

            .Level1L => {
                if(majorsLevels.line[high].?.map != 0) break :sw {};
                @call(.never_inline, &Radix.Level1_T.Line.free, .{
                    majorsLevels.line[high].?.line
                }) catch {};
                majorsLevels.line[high].?.line = null; continue :sw .Level0O;
            },

            .Level0O => {
                @call(.never_inline, &Radix.Level1_T.Level.free, .{
                    majorsLevels.line[high]
                }) catch {};
                majorsLevels.line[high] = null;
                majorsLevels.map &= ~(@as(u16, @intCast(0x01)) << high);
            },
        }
        break :r {};
    };
}

pub fn search(M: Drivers.MajorNum_T) Drivers.DriverErr_T!*Drivers.Driver_T {
    return if(@call(.always_inline, &valid_path, .{
        @as(u4, @intCast((M >> 4) & 0x0F)),
        @as(u2, @intCast((M >> 2) & 0x03)),
        @as(u2, @intCast(M & 0x03))
    })) majorsLevels.line[(M >> 4) & 0x0F].?.line.?[(M >> 2) & 0x03].?.line.?[M & 0x03].? else Drivers.DriverErr_T.NonFound;
}

// == Saturn Radix Major Test ==

const TestErr_T: type = error {
    UndefinedAction,
    UnreachableCode,
};
const MaxMajorNum: Drivers.MajorNum_T = 63;
var majorTester: Drivers.Driver_T = .{
    .major = 0,
    .ops = .{
        .open = null,
        .close = null,
        .read = &struct {
            pub fn read(_: Drivers.MinorNum_T, _: usize) Drivers.DriverErr_T![]u8 {
                return @constCast("Hello, World!");
            }
        }.read,
        .write = &struct {
            pub fn write(_: Drivers.MinorNum_T, _: []const u8) Drivers.DriverErr_T!void {

            }
        }.write,
        .minor = &struct {
            pub fn minor(_: Drivers.MinorNum_T) Drivers.DriverErr_T!void {

            }
        }.minor,
        .ioctrl = &struct {
            fn minor(_: Drivers.MinorNum_T, _: usize, _: usize) Drivers.OpsErr_T!usize {
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
            Drivers.DriverErr_T.MajorCollision => {},
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
            Drivers.DriverErr_T.DoubleFree => {},
            else => return TestErr_T.UnreachableCode,
        };
        try add(&majorTester);
        if((try search(majorTester.major)).major != majorTester.major) {
            return TestErr_T.UndefinedAction;
        }
        try del(majorTester.major);
        del(majorTester.major) catch |err| switch(err) {
            Drivers.DriverErr_T.DoubleFree => {},
            else => return TestErr_T.UnreachableCode,
        };
        _ = search(majorTester.major) catch |err| switch(err) {
            Drivers.DriverErr_T.NonFound => {},
            else => return TestErr_T.UnreachableCode,
        };
        majorTester.major += 1;
    }
}

test "Major Search With 0 Major" {
    majorTester.major = 0;
    for(0..MaxMajorNum) |_| {
        _ = search(majorTester.major) catch |err| switch(err) {
            Drivers.DriverErr_T.NonFound => {
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
            Drivers.DriverErr_T.MajorCollision => {},
            else => return TestErr_T.UnreachableCode,
        };
        if((try search(majorTester.major)).major != majorTester.major) {
            return TestErr_T.UndefinedAction;
        }
        majorTester.major += 1;
    }
}
