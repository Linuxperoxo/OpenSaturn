// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Driver_T: type = @import("types.zig").Driver_T;
const DriverErr_T: type = @import("types.zig").DriverErr_T;
const Ops_T: type = @import("types.zig").Ops_T;
const OpsErr_T: type = @import("types.zig").OpsErr_T;
const Radix: type = @import("radix.zig");

const MajorNum_T: type = @import("types.zig").MajorNum_T;

const Allocator: type = @import("allocator.zig");
const AllocatorErr_T: type = @import("allocator.zig").AllocatorErr_T;

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
var majorsLevels: Radix.Level1 = .{
    .line = .{
        null
    } ** 16,
    .map = 0,
};



pub fn add(D: *const Driver_T) DriverErr_T!void {
    return r: {
        const bunch: u4 = (D.major >> 2) & 0x0F;
        const offset: u2 = @intCast(D.major & 0x03);
        if((bitmap ^ 0xFFFF) == 0) DriverErr_T.OutMajor;
        if(driversBunch[bunch].bunch[offset]) |_| DriverErr_T.MajorCollision;
        driversBunch[bunch].bunch[offset] = @call(.never_inline, &Allocator.alloc, .{}) catch break :r DriverErr_T.InternalError;
        driversBunch[bunch].map |= 0x01 << offset;
        bitmap |= if((driversBunch[bunch].map ^ 0x03) != 0) (0x01 << bunch) else break :r {};
    };
}

pub fn del(M: MajorNum_T) DriverErr_T!void {
    return r: {
        const bunch: u4 = @intCast((M >> 2) & 0x0F);
        const offset: u2 = @intCast(M & 0x03);
        @call(.never_inline, &Allocator.free, .{
            driversBunch[bunch].bunch[offset] orelse break :r DriverErr_T.DoubleFree
        }) catch break :r DriverErr_T.InternalError;
        driversBunch[bunch].bunch[offset] = null;
        driversBunch[bunch].map &= (~(0x01 << offset));
        bitmap &= if(driversBunch[bunch].map == 0) (~(0x0001 << bunch)) else break :r {};
    };
}

pub fn search(M: MajorNum_T) DriverErr_T!*Driver_T {
    return if(driversBunch[(M >> 2) & 0x0F].bunch[M & 0x03]) |_| driversBunch[(M >> 2) & 0x0F].bunch[M & 0x03].? else DriverErr_T.NonFound;
}
