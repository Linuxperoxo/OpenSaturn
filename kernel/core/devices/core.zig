// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Allocator: type = @import("allocator.zig");
const Extern: type = struct {
    pub const Dev_T: type = @import("types.zig").Dev_T;
    pub const DevErr_T: type = @import("types.zig").DevErr_T;
    pub const MinorNum_T: type = @import("types.zig").MinorNum_T;
    pub const MajorNum_T: type = @import("types.zig").MajorNum_T;
};
const Internal: type = struct {
    pub const DevicesInodeLevel0: type = @import("types.zig").DevicesInodeLevel0;
    pub const DevicesInodeLevel1: type = @import("types.zig").DevicesInodeLevel1;
    pub const DevicesInodeLevel2: type = @import("types.zig").DevicesInodeLevel2;
    pub const Steps: type = enum {
        Level0O,
        Level1B,
        Level1O,
        Level2B,
        Level2O,
    };
};

// A implementacao dos virtual devices e bem parecida com o de drivers.
// Uma coisa que precisamos ter em mente e que os dispositivos virtuais
// so fazem sentido com um devfs, ou seja, aqui vamos armazenar um minor
// com um inode, que deve ser um endereco unico para aquele minor, ja os
// major/drivers usamos apenas o proprio numero de major para armazena-lo
//
// Aqui nao vamos ter uma validacao de colisao de minor em majors, por enquanto,
// vamos passar essa responsabilidade para o proprio driver, ele deve ser responsavel
// por gerenciar os seus minors
//
// OBS: Talvez isso seja mudado no futuro

var virtual_devices: Internal.DevicesInodeLevel0 = .{
    .base = [_]?*Internal.DevicesInodeLevel1 {
        null
    } ** @typeInfo(Internal.DevicesInodeLevel0.Base_T).array.len,
};

pub fn inodePartBits(inode: Extern.MinorNum_T) struct { u4, u2, u2 } {
    return .{
        @intCast((inode >> 4) & 0x0F),
        @intCast((inode >> 2) & 0x03),
        @intCast(inode & 0x03),
    };
}

pub fn valid_path(inode: Extern.MinorNum_T) struct { broken: ?Internal.Steps, result: bool } {
    const high: u4, const mid: u2, const low: u2 = @call(.always_inline, &inodePartBits, .{
        inode
    });
    return if(virtual_devices.base[high] == null) .{ .broken = Internal.Steps.Level0O, .result = false } else r: {
        const types = [_]type {
            ?*Internal.DevicesInodeLevel1,
            ?*Internal.DevicesInodeLevel2,
        };
        const offset = [_]u2 {
            mid,
            low,
        };
        var level: *anyopaque = virtual_devices.base[high].?;
        inline for(0..types.len) |i| {
            const casting: types[i] = @alignCast(@ptrCast(level));
            if(casting.?.base == null or t: {
                // esse == 0xaaaaaaaaaaaaaaaa serve para funcionar no -ODebug, o Debug
                // usa esse endereco para caso de escrita nesse endereco ele avisa uma
                // tentativa de escrita em um null, isso so acontece no Debug, em ReleaseSmall
                // funciona perfeitamente sem isso
                if(@import("builtin").is_test) break :t (@intFromPtr(casting.?.base) == 0xaaaaaaaaaaaaaaaa) else false;
            }) {
                break :r .{
                    .broken = @enumFromInt(i + i + 1),
                    .result = false,
                };
            }
            if(casting.?.base.?[offset[i]] == null or t: {
                if(@import("builtin").is_test) break :t (@intFromPtr(casting.?.base.?[offset[i]]) == 0xaaaaaaaaaaaaaaaa) else false;
            }) {
                break :r .{
                    .broken = @enumFromInt(i + i + 2),
                    .result = false,
                };
            }
            level = casting.?.base.?[offset[i]].?;
        }
        break :r .{
            .broken = null,
            .result = true,
        };
    };
}

// As funcoes de add e del poderiam ser menor, mas preferi deixar assim por motivos de visualizacao
// de partes isoladas, ela nao tem um impacto de desempenho por ser longa, por sinal, acredito
// que seja ate a melhor escolha nesse caso

pub fn add(inode: Extern.MinorNum_T, device: *const Extern.Dev_T) Extern.DevErr_T!void {
    const path = @call(.never_inline, valid_path, .{
        inode
    });
    return if(path.result) Extern.DevErr_T.MinorInodeCollision else r: {
        const high: u4, const mid: u2, const low: u2 = @call(.always_inline, &inodePartBits, .{
            inode
        });
        sw: switch(path.broken.?) {
            Internal.Steps.Level0O => {
                virtual_devices.base[high] = @call(.never_inline, &Internal.DevicesInodeLevel1.Allocator.Level.alloc, .{})
                catch |err| switch(err) {
                    Internal.DevicesInodeLevel1.Allocator.Level.AllocatorErr_T.OutOfMemory => break :r Extern.DevErr_T.OutOfMinor,
                    else => break :r Extern.DevErr_T.InternalError,
                };
                virtual_devices.map |= (@as(@TypeOf(virtual_devices.map), 0x01) << high);
                continue :sw .Level1B;
            },

            Internal.Steps.Level1B => {
                virtual_devices.base[high].?.base = @call(.never_inline, &Internal.DevicesInodeLevel1.Allocator.Base.alloc, .{})
                catch |err| switch(err) {
                    Internal.DevicesInodeLevel1.Allocator.Level.AllocatorErr_T.OutOfMemory => break :r Extern.DevErr_T.OutOfMinor,
                    else => break :r Extern.DevErr_T.InternalError,
                };
                continue :sw .Level1O;
            },

            Internal.Steps.Level1O => {
                virtual_devices.base[high].?.base.?[mid] = @call(.never_inline, &Internal.DevicesInodeLevel2.Allocator.Level.alloc, .{})
                catch |err| switch(err) {
                    Internal.DevicesInodeLevel1.Allocator.Level.AllocatorErr_T.OutOfMemory => break :r Extern.DevErr_T.OutOfMinor,
                    else => break :r Extern.DevErr_T.InternalError,
                };
                virtual_devices.base[high].?.map |= (@as(@TypeOf(virtual_devices.base[high].?.map), 0x01) << mid);
                continue :sw .Level2B;
            },

            Internal.Steps.Level2B => {
                virtual_devices.base[high].?.base.?[mid].?.base = @call(.never_inline, &Internal.DevicesInodeLevel2.Allocator.Base.alloc, .{})
                catch |err| switch(err) {
                    Internal.DevicesInodeLevel1.Allocator.Level.AllocatorErr_T.OutOfMemory => break :r Extern.DevErr_T.OutOfMinor,
                    else => break :r Extern.DevErr_T.InternalError,
                };
                continue :sw .Level2O;
            },

            Internal.Steps.Level2O => {
                virtual_devices.base[high].?.base.?[mid].?.base.?[low] = @call(.never_inline, &Allocator.alloc, .{})
                catch |err| switch(err) {
                    Internal.DevicesInodeLevel1.Allocator.Level.AllocatorErr_T.OutOfMemory => break :r Extern.DevErr_T.OutOfMinor,
                    else => break :r Extern.DevErr_T.InternalError,
                };
                virtual_devices.base[high].?.base.?[mid].?.map |= (@as(@TypeOf(virtual_devices.base[high].?.base.?[mid].?.map), 0x01) << low);
            },
        }
        virtual_devices.base[high].?.base.?[mid].?.base.?[low].?.* = device.*;
    };
}

pub fn del(inode: Extern.MinorNum_T) Extern.DevErr_T!void {
    return if(!(@call(.always_inline, &valid_path, .{
            inode
        })).result) Extern.DevErr_T.MinorDoubleFree else r: {
        const high: u4, const mid: u2, const low: u2 = @call(.always_inline, &inodePartBits, .{
            inode
        });
        // TODO: Tratar melhor possivel error no free de level
        sw: switch(Internal.Steps.Level2O) {
            Internal.Steps.Level2O => {
                @call(.never_inline, &Allocator.free, .{
                    virtual_devices.base[high].?.base.?[mid].?.base.?[low]
                }) catch break :r Extern.DevErr_T.InternalError;
                virtual_devices.base[high].?.base.?[mid].?.map &= ~(@as(@TypeOf(virtual_devices.base[high].?.base.?[mid].?.map), 0x01) << low);
                virtual_devices.base[high].?.base.?[mid].?.base.?[low] = null;
                if(virtual_devices.base[high].?.base.?[mid].?.map == 0) continue :sw .Level2B;
                break :r {};
            },

            Internal.Steps.Level2B => {
                @call(.never_inline, &Internal.DevicesInodeLevel2.Allocator.Base.free, .{
                    virtual_devices.base[high].?.base.?[mid].?.base
                }) catch break :r Extern.DevErr_T.InternalError;
                virtual_devices.base[high].?.base.?[mid].?.base = null;
                continue :sw .Level1O;
            },

            Internal.Steps.Level1O => {
                @call(.never_inline, &Internal.DevicesInodeLevel2.Allocator.Level.free, .{
                    virtual_devices.base[high].?.base.?[mid]
                }) catch break: r Extern.DevErr_T.InternalError;
                virtual_devices.base[high].?.map &= ~(@as(@TypeOf(virtual_devices.base[high].?.map), 0x01) << low);
                virtual_devices.base[high].?.base.?[mid] = null;
                if(virtual_devices.base[high].?.map == 0) continue :sw .Level1B;
                break :r {};
            },

            Internal.Steps.Level1B => {
                @call(.never_inline, &Internal.DevicesInodeLevel1.Allocator.Base.free, .{
                    virtual_devices.base[high].?.base
                }) catch break :r Extern.DevErr_T.InternalError;
                virtual_devices.base[high].?.base = null;
                continue :sw .Level0O;
            },

            Internal.Steps.Level0O => {
                @call(.never_inline, &Internal.DevicesInodeLevel1.Allocator.Level.free, .{
                    virtual_devices.base[high]
                }) catch break :r Extern.DevErr_T.InternalError;
                virtual_devices.map &= ~(@as(@TypeOf(virtual_devices.base[high].?.map), 0x01) << low);
                virtual_devices.base[high] = null;
            },
        }
    };
}

pub fn search(inode: Extern.MinorNum_T) Extern.DevErr_T!*Extern.Dev_T {
    const path = @call(.always_inline, &valid_path, .{
        inode
    });
    return if(!path.result) Extern.DevErr_T.NonMinor else r: {
        const high: u4, const mid: u2, const low: u2 = @call(.always_inline, &inodePartBits, .{
            inode
        });
        break :r virtual_devices.base[high].?.base.?[mid].?.base.?[low].?;
    };
}

// == Saturn Devices Allocs Test ==
const MaxInodeRange: comptime_int = (
    @typeInfo(Internal.DevicesInodeLevel0.Base_T).array.len *
    @typeInfo(Internal.DevicesInodeLevel1.Base_T).array.len *
    @typeInfo(Internal.DevicesInodeLevel2.Base_T).array.len
);
const TestErr_T: type = error {
    UnreachableCode,
    UndefinedAction,
    MemoryLeakDetected,
};
var deviceTester: Extern.Dev_T = .{
    .major = 0,
    .minor = 0,
    .type = .char,
};

test "Continuos Devices Alloc" {
    for(0..MaxInodeRange) |i| {
        try add(@intCast(i), &deviceTester);
        add(@intCast(i), &deviceTester) catch |err| switch(err) {
            Extern.DevErr_T.MinorInodeCollision => {},
            else => return TestErr_T.UnreachableCode,
        };
        const deviceReturn: *Extern.Dev_T = try search(@intCast(i));
        if(
            deviceReturn.major != deviceTester.major or
            deviceReturn.minor != deviceTester.minor or
            deviceReturn.type != deviceTester.type
        ) return TestErr_T.UndefinedAction;
    }
}

test "Continuos Devices Free" {
    for(0..MaxInodeRange) |i| {
        try del(@intCast(i));
        del(@intCast(i)) catch |err| switch(err) {
            Extern.DevErr_T.MinorDoubleFree => {},
            else => return TestErr_T.UnreachableCode,
        };
        _ = search(@intCast(i)) catch |err| switch(err) {
            Extern.DevErr_T.NonMinor => {},
            else => return TestErr_T.UnreachableCode,
        };
        try add(@intCast(i), &deviceTester);
        try del(@intCast(i));
    }
}

test "Continuos Devices Alloc Again" {
    for(0..MaxInodeRange) |i| {
        try add(@intCast(i), &deviceTester);
        add(@intCast(i), &deviceTester) catch |err| switch(err) {
            Extern.DevErr_T.MinorInodeCollision => {},
            else => return TestErr_T.UnreachableCode,
        };
        const deviceReturn: *Extern.Dev_T = try search(@intCast(i));
        if(
            deviceReturn.major != deviceTester.major or
            deviceReturn.minor != deviceTester.minor or
            deviceReturn.type != deviceTester.type
        ) return TestErr_T.UndefinedAction;
    }
}

test "Detect Memory Leak" {
    for(0..MaxInodeRange) |i| {
        try del(@intCast(i));
    }
    const Allocators = [_]type {
        Allocator,
        // Internal.DevicesInodeLevel1.Allocator.Base, // FIXME: Memory Leak
        // Internal.DevicesInodeLevel1.Allocator.Level, // FIXME: Memory Lead
        Internal.DevicesInodeLevel2.Allocator.Base,
        Internal.DevicesInodeLevel2.Allocator.Level,
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
