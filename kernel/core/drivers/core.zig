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
    const Allocator: type = @import("allocator.zig");
};

const config: type = @import("root").config;
const modules: type = @import("root").modules;

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

fn valid_path(high: u4, mid: u2, low: u2) bool {
    return (
        @bitCast((majorsLevels.map >> high) & 0x01) and
        @bitCast((majorsLevels.line[high].?.map >> mid) & 0x01) and
        @bitCast((majorsLevels.line[high].?.line[mid].?.map >> low) & 0x01)
    );
}

fn obsolete_path(high: u4, mid: u2) error { none }!Steps {
    return if(@bitCast((majorsLevels.map >> high) ^ 0x01)) Steps.Level0 else r: {
        if(majorsLevels.line[high].?.line == null) break :r Steps.Level1;
        if(majorsLevels.line[high].?.line[mid].?.line == null) break :r Steps.Level2;
        break :r error.none;
    };
}

pub fn add(D: *const Drivers.Driver_T) Drivers.DriverErr_T!void {
    return if(@call(.always_inline, &valid_path, .{
        (D.major >> 4) & 0x0F, (D.major >> 2) & 0x03, D.major & 0x03
    })) Drivers.DriverErr_T.MajorCollision else r: {
        const high: u4 = (D.major >> 4) & 0x0F;
        const mid: u4 = (D.major >> 2) & 0x03;
        const low: u4 = D.major & 0x03;
        t: {
            sw: switch(@call(.always_inline, &obsolete_path, .{
                high, mid
            }) catch break :t {}) {
                .Level0 => {
                    majorsLevels.line[high] = @call(.never_inline, &Radix.Allocators.Levels.alloc, .{
                        Radix.Level1_T,
                    }) catch Drivers.DriverErr_T.InternalError;
                    majorsLevels.map |= 0x01 << high; continue :sw .Level1;
                },

                .Level1 => {
                    majorsLevels.line[high].?.line = @call(.never_inline, &Radix.Allocators.Lines.alloc, .{}) catch Drivers.DriverErr_T.InternalError;
                    majorsLevels.line[high].?.line[mid] = @call(.never_inline, &Radix.Allocators.Levels.alloc, .{
                        Radix.Level2_T,
                    }) catch {
                        @call(.never_inline, &Radix.Allocators.Lines.free, .{
                            majorsLevels.line[high].?.line
                        }); break :r Drivers.DriverErr_T.InternalError;
                    };
                    majorsLevels.line[high].?.map |= 0x01 << mid; continue :sw .Level2;
                },

                .Level2 => {
                    majorsLevels.line[high].?.line[mid].?.line = @call(.never_inline, &Radix.Allocators.Lines.alloc, .{}) catch Drivers.DriverErr_T.InternalError;
                    majorsLevels.line[high].?.line[mid].?.line[low] = @call(.never_inline, &Drivers.Allocator.alloc, .{}) catch {
                        @call(.never_inline, &Radix.Allocators.Lines.free, .{
                            majorsLevels.line[high].?.line
                        }); break :r Drivers.DriverErr_T.InternalError;
                    };
                    majorsLevels.line[high].?.line[mid].?.map |= 0x01 << low; break :t {};
                },
            }
        }
        majorsLevels.line[high].?.line[mid].?.line[low].* = D.*;
    };
}

pub fn del(M: Drivers.MajorNum_T) Drivers.DriverErr_T!void {
    return if(!@call(.always_inline, &valid_path, .{
        (M >> 4) & 0x0F, (M >> 2) & 0x03, M & 0x03
    })) Drivers.DriverErr_T.DoubleFree else r: {
        // TODO: Implement
    };
}

pub fn search(M: Drivers.MajorNum_T) Drivers.DriverErr_T!*Drivers.Driver_T {
    return if(@call(.always_inline, &valid_path, .{
        (M >> 4) & 0x0F, (M >> 2) & 0x03, M & 0x03
    })) majorsLevels.line[(M >> 4) & 0x0F].?.line[(M >> 2) & 0x03].?.line[M & 0x03].? else Drivers.DriverErr_T.NonFound;
}
