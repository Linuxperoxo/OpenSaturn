// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
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

// Por enquanto vou usar tamanho fixo, vou usar um
// padrao para drivers que ja estao linkados ao kernel
// logo na compilacao, ele seram armazenados nesse array.
// Depois isso sera modificado para permitir mais major

// A ideia de usar arrray por enquanto e para conseguir
// ter o maximo de desempenho ao tentar procurar um major,
// ja que aqui e onde acontece todo acesso a um major para
// alguma operacao. Pretendo melhorar esse algoritmo para
// ter uma alocacao mais lenta, porem maior, mas a busca
// precisa ser extremamente rapida
var majorsLevels: Radix.Level0_T = .{
    .line = .{
        null
    } ** 16,
    .map = 0,
};

const Steps: type = enum {
    Level0,
    Level1,
    Level2,
};

var count: usize = 0;
fn valid_path(high: u4, mid: u2, low: u2) bool {
    return (
        (majorsLevels.line[high] != null) and
        (majorsLevels.line[high].?.line != null) and
        (majorsLevels.line[high].?.line.?[mid] != null) and
        (majorsLevels.line[high].?.line.?[mid].?.line != null) and
        (majorsLevels.line[high].?.line.?[mid].?.line.?[low] != null)
    );
}

fn obsolete_path(high: u4, mid: u2) error { none }!Steps {
    return r: {
        if(majorsLevels.line[high] == null) break :r .Level0;
        if(majorsLevels.line[high].?.line == null) break :r .Level1;
        if(majorsLevels.line[high].?.line.?[mid] == null) break :r .Level1;
        if(majorsLevels.line[high].?.line.?[mid].?.line == null) break :r .Level2;
        break :r error.none;
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
        t: {
            sw: switch(@call(.always_inline, &obsolete_path, .{
                high, mid
            }) catch break :t {}) {
                .Level0 => {
                    majorsLevels.line[high] = @call(.never_inline, &Radix.Allocators.Levels.alloc, .{
                        Radix.Level1_T
                    }) catch |err| switch(err) {
                        Radix.Allocators.Levels.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
                        else => {
                            break :r Drivers.DriverErr_T.InternalError;
                        },
                    };
                    majorsLevels.map |= @as(u16, @intCast(0x01)) << high;
                    continue :sw .Level1;
                },

                .Level1 => {
                    majorsLevels.line[high].?.line = y: {
                        if(majorsLevels.line[high].?.line) |_| break :y majorsLevels.line[high].?.line;
                        break :y @alignCast(@ptrCast(@call(.never_inline, &Radix.Allocators.Lines.alloc, .{}) catch |err| switch(err) {
                            Radix.Allocators.Lines.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
                            else => {
                                break :r Drivers.DriverErr_T.InternalError;
                            },
                        }));
                    };
                    majorsLevels.line[high].?.line.?[mid] = @call(.never_inline, &Radix.Allocators.Levels.alloc, .{
                        Radix.Level2_T
                    }) catch |err| switch(err) {
                        Radix.Allocators.Levels.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
                        else => {
                            break :r Drivers.DriverErr_T.InternalError;
                        },
                    };
                    majorsLevels.line[high].?.map |= @as(u4, @intCast(0x01)) << mid;
                    continue :sw .Level2;
                },

                .Level2 => {
                    majorsLevels.line[high].?.line.?[mid].?.line = @alignCast(@ptrCast(@call(.never_inline, &Radix.Allocators.Lines.alloc, .{}) catch |err| switch(err) {
                        Radix.Allocators.Lines.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
                        else => {
                            break :r Drivers.DriverErr_T.InternalError;
                        },
                    }));
                },
            }
        }
        majorsLevels.line[high].?.line.?[mid].?.line.?[low] = @call(.never_inline, &Drivers.Allocator.alloc, .{}) catch |err| switch(err) {
            Drivers.Allocator.AllocatorErr_T.OutOfMemory => break :r Drivers.DriverErr_T.OutMajor,
            else => {
                break :r Drivers.DriverErr_T.InternalError;
            },
        };
        majorsLevels.line[high].?.line.?[mid].?.map |= @as(u4, @intCast(0x01)) << low;
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
        sw: switch(Steps.Level2) {
            .Level2 => {
                @call(.never_inline, &Drivers.Allocator.free, .{
                    majorsLevels.line[high].?.line.?[mid].?.line.?[low].?
                }) catch {};
                while(true) {}
                majorsLevels.line[high].?.line.?[mid].?.line.?[low] = null;
                majorsLevels.line[high].?.line.?[mid].?.map &= ~(@as(u4, @intCast(0x01)) << low);
                if(majorsLevels.line[high].?.line.?[mid].?.map == 0) {
                    @call(.never_inline, &Radix.Allocators.Lines.free, .{
                        @as(*anyopaque, @alignCast(@ptrCast(majorsLevels.line[high].?.line.?[mid].?.line.?)))
                    }) catch {};
                    majorsLevels.line[high].?.line.?[mid].?.line = null;
                    continue :sw .Level1;
                }
                break :sw {};
            },

            .Level1 => {
                @call(.never_inline, &Radix.Allocators.Levels.free, .{
                    @as(*anyopaque, @alignCast(@ptrCast(majorsLevels.line[high].?.line.?[mid].?)))
                }) catch {};
                majorsLevels.line[high].?.line.?[mid] = null;
                majorsLevels.line[high].?.map &= ~(@as(u4, @intCast(0x01)) << mid);
                if(majorsLevels.line[high].?.map == 0) {
                    @call(.never_inline, &Radix.Allocators.Lines.free, .{
                        @as(*anyopaque, @alignCast(@ptrCast(majorsLevels.line[high].?.line.?)))
                    }) catch {};
                    majorsLevels.line[high].?.line = null;
                    continue :sw .Level0;
                }
            },

            .Level0 => {
                @call(.never_inline, &Radix.Allocators.Levels.free, .{
                    @as(*anyopaque, @alignCast(@ptrCast(majorsLevels.line[high].?)))
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

fn read(_: Drivers.MinorNum_T, _: usize) []u8 {
    return @constCast("Hello, World!");
}

fn write(_: Drivers.MinorNum_T, _: []const u8) void {
    
}

fn ioctrl(_: Drivers.MinorNum_T, _: usize, _: usize) Drivers.OpsErr_T!usize {
    return 10;
}

fn minor(_: Drivers.MinorNum_T) Drivers.DriverErr_T!void {

}

fn phase0(major: *Drivers.Driver_T) anyerror!void {
    major.major = 0;
    var collision: usize = 0;
    for(0..64) |_| {
        //const high: u4 = @intCast((major.major >> 4) & 0x0F);
        //const mid: u2 = @intCast((major.major >> 2) & 0x03);
        //const low: u2 = @intCast(major.major & 0x03);
        add(major) catch |err| switch(err) {
            Drivers.DriverErr_T.MajorCollision => { collision += 1; },
            else => return err,
        };
        //std.debug.print("0x{x}\n", .{
        //    @intFromPtr(majorsLevels.line[high].?.line.?[mid].?.line.?[low].?)
        //});
        //while(i == 3) {}
        //if((try search(major.major)).major != major.major) {
        //    return Drivers.DriverErr_T.NonFound;
        //}
        add(major) catch |err| switch(err) {
            Drivers.DriverErr_T.MajorCollision => {},
            else => return err,
        };
        major.major += 1;
    }
    std.debug.print("{d}\n", .{
        collision
    });
}

fn phase1(major: *Drivers.Driver_T) anyerror!void {
    major.major = 0;
    for(0..53) |_| {
        try @call(.never_inline, del, .{
            major.major
        });
        _ = search(major.major) catch |err| switch(err) {
            Drivers.DriverErr_T.NonFound => {},
            else => return err,
        };
        major.major += 1;
    }
}

fn phase2(major: *Drivers.Driver_T) anyerror!void {
    major.major = 0;
    for(0..52) |_| {
        try add(major);
        if((try search(major.major)).major != major.major) {
            return Drivers.DriverErr_T.NonFound;
        }
        add(major) catch |err| switch(err) {
            Drivers.DriverErr_T.MajorCollision => {},
            else => return err,
        };
        major.major += 1;
    }
}

pub fn main() anyerror!void {
    var major: Drivers.Driver_T = .{
        .major = 0,
        .ops = .{
            .read = &read,
            .write = &write,
            .ioctrl = &ioctrl,
            .minor = &minor,
            .close = null,
            .open = null,
        },
    };
    phase0(&major) catch |err| {
        std.debug.print("Phase0 Error: {s}\n", .{
            @errorName(err)
        });
        return {};
    };
    std.debug.print("Done!\n", .{});
}
