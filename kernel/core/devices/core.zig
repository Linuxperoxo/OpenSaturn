// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Dev_T: type = @import("types.zig").Dev_T;
const DevErr_T: type = @import("types.zig").DevErr_T;
const DevMajorBunch_T: type = @import("types.zig").DevMajorBunch_T;
const MinorNum_T: type = @import("types.zig").MinorNum_T;
const MajorNum_T: type = @import("root").interfaces.drivers.types.MajorNum_T;

const Allocator: type = @import("allocator.zig");

var devicesBunch= [_]DevMajorBunch_T {.{
    DevMajorBunch_T {
        .bunch = .{
            null
        } ** 16,
        .part = null,
        .regs = 0,
        .busy = 0,
    },
}} ** 16;

// O algoritmo usado aqui nao vem de nenhum livro ou outros projetos,
// e um algoritmo desenhado exclusivamente para o saturn.

const Steps: type = enum {
    shot,
    rec,
    miss,
    new
};

pub fn add(D: *const Dev_T) DevErr_T!void {
    return r: {
        const bunch: u4, const device: u4 = t: {
            var localBunch = D.major & 0x0F;
            sw: switch(Steps.shot) {
                .shot => {
                    if(devicesBunch[localBunch].bunch[D.minor & 0x0F] == null) break :t .{ localBunch, D.minor & 0x0F };
                    if(devicesBunch[localBunch].bunch[D.minor & 0x0F].?.minor == D.minor) break :r DevErr_T.MinorCollision;
                    if(devicesBunch[localBunch].bunch[(D.minor >> 4) & 0x0F] == null) break :t .{ localBunch, (D.minor >> 4) & 0x0F };
                    if(devicesBunch[localBunch].bunch[(D.minor >> 4) & 0x0F].?.minor == D.minor) break :r DevErr_T.MinorCollision;
                    continue :sw .miss;
                },

                .rec => {
                    localBunch = if(devicesBunch[localBunch].part) |_| devicesBunch[localBunch].part.? else continue :sw .new;
                    continue :sw .shot;
                },

                .miss => {
                    // verificando se todos os slots de minor estao
                    // sendo usados
                    //
                    // digamos que temos 4 slots e estamos usamando os
                    // slots 0...2, os bits estariam assim 0111, ou seja,
                    // temos ainda um slot, entao  fazemos um xor 0111 ^ 1111
                    // se isso retornar algo diferente de 0, e pq temos slots
                    // ainda, funcionaria comparar o .alloc com 2^16, mas assim
                    // simplificamos
                    if((devicesBunch[localBunch].alloc ^ 0xFFFF) == 0) continue :sw .rec;
                    const localDevice = y: {
                        for(0..16) |i| {
                            // o bitcast nesse caso faz casting para bool, como queremos
                            // capturar algum bit que e 0 usamos um xor para comparar
                            if(@bitCast((devicesBunch[localBunch].alloc >> i) ^ 0x01)) break :y i;
                            if(devicesBunch[localBunch].bunch[i].?.minor == D.minor) break :r DevErr_T.MinorCollision;
                        }
                        continue :sw .new;
                    };
                    devicesBunch[localBunch].miss |= 0x01 << localDevice; break :t .{ localBunch, localDevice };
                },

                .new => {
                    const bunchChild = y: {
                        for(0..devicesBunch.len) |i| {
                            if(devicesBunch[i].alloc == 0) break :y i;
                        }
                        break :r DevErr_T.OutOfMinor;
                    };
                    // parent bunch to child link
                    devicesBunch[localBunch].part = bunchChild; break :t .{ bunchChild, D.minor & 0x0F }; // D.minor & 0x0F is default
                },
            }
        };
        devicesBunch[bunch].bunch[device] = @call(.never_inline, &Allocator.alloc, .{}) catch DevErr_T.InternalError;
        devicesBunch[bunch].bunch[device].?.* = D.*;
        devicesBunch[bunch].part = if(bunch != (D.major & 0x0F)) bunch else devicesBunch[bunch].part;
        devicesBunch[bunch].alloc |= 0x01 << device;
    };
}

pub fn del(Ma: MajorNum_T, Mi: MinorNum_T) DevErr_T!void {
    return r: {
        const bunch: u4, const device: u4, const parent: ?u4 = t: {
            var localBunch: u4 = Ma & 0x0F;
            var localParent: ?u4 = null;
            sw: switch(Steps.shot) {
                .shot => {
                    if(devicesBunch[localBunch].bunch[Mi & 0x0F]) |_| {
                        if(devicesBunch[localBunch].bunch[Mi & 0x0F].?.minor == Mi) break :t .{ localBunch, Mi & 0x0F, null };
                    }
                    if(devicesBunch[localBunch].bunch[(Mi >> 4) & 0x0F]) |_| {
                        if(devicesBunch[localBunch].bunch[(Mi >> 4) & 0x0F].?.minor == Mi) break :t .{ localBunch, (Mi >> 4) & 0x0F, null };
                    }
                    continue :sw .miss;
                },

                .rec => {
                    localBunch, localParent = y: {
                        break :y .{
                            if(devicesBunch[localBunch].part) |_| devicesBunch[localBunch].part.? else break :sw {},
                            devicesBunch[localBunch].part.?,
                        };
                    };
                    continue :sw .shot;
                },

                .miss => {
                    if(devicesBunch[localBunch].miss == 0 or devicesBunch[localBunch].alloc == 0) continue :sw .rec;
                    const localDevice = y: {
                        for(0..16) |i| {
                            if(@bitCast((devicesBunch[localBunch].miss >> i) & 0x01)) {
                                if(devicesBunch[localBunch].bunch[i].?.minor == Mi) break :y i;
                            }
                        }
                        continue :sw .rec;
                    };
                    devicesBunch[localBunch].miss &= (~(0x01 << localDevice)); break :t .{ localBunch, localDevice, localParent };
                },
            }
            break :r DevErr_T.MinorDoubleFree;
        };
        @call(.never_inline, &Allocator.free, .{
            devicesBunch[bunch].bunch[device].?
        });
        devicesBunch[bunch].bunch[device] = null;
        devicesBunch[bunch].alloc &= (~(0x01 << device));
        devicesBunch[t: {
            if(parent == null) break :r {};
            if(devicesBunch[bunch].alloc != 0) break :r {};
            break :t parent.?;
        }].part = null;
    };
}

pub fn exist(Ma: MajorNum_T, Mi: MinorNum_T) DevErr_T!*const Dev_T {
    return r: {
        var localBunch: u4 = Ma & 0x0F;
        sw: switch(Steps.shot) {
            .shot => {
                if(devicesBunch[localBunch].bunch[Mi & 0x0F]) |_| {
                    if(devicesBunch[localBunch].bunch[Mi & 0x0F].?.minor == Mi) break :r devicesBunch[localBunch].bunch[Mi & 0x0F].?;
                }
                if(devicesBunch[localBunch].bunch[(Mi >> 4) & 0x0F]) |_| {
                    if(devicesBunch[localBunch].bunch[(Mi >> 4) & 0x0F].?.minor == Mi) break :r devicesBunch[localBunch].bunch[Mi & 0x0F];
                }
                continue :sw .miss;
            },

            .rec => {
                localBunch = if(devicesBunch[localBunch].part) |_| devicesBunch[localBunch].part.? else break :r DevErr_T.NonMinor;
                continue :sw .shot;
            },

            .miss => {
                if(devicesBunch[localBunch].miss == 0) continue :sw .rec;
                for(0..16) |i| {
                    if(@bitCast((devicesBunch[localBunch].miss >> i) & 0x01)) {
                        if(devicesBunch[localBunch].bunch[i].?.minor == Mi) break :r devicesBunch[localBunch].bunch[i].?;
                    }
                }
                continue :sw .rec;
            },
        }
        unreachable;
    };
}
