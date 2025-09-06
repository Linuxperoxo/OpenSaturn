// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Driver_T: type = @import("types.zig").Driver_T;
const DriverErr_T: type = @import("types.zig").DriverErr_T;
const Ops_T: type = @import("types.zig").Ops_T;
const OpsErr_T: type = @import("types.zig").OpsErr_T;
const DriversBunch_T: type = @import("types.zig").DriversBunch_T;

const MajorNum_T: type = @import("types.zig").MajorNum_T;

const Allocator: type = @import("allocator.zig");
const AllocatorErr_T: type = @import("allocator.zig").AllocatorErr_T;

// Por enquanto vou usar tamanho fixo, vou usar um
// padrao para drivers que ja estao linkados ao kernel
// logo na compilacao, ele seram armazenados nesse array,
// para drivers carregado dinamicamente vamos alocar em
// outro lugar
var driversBunch = r: {
    var bunchTmp: [16]DriversBunch_T = undefined;
    for(0..bunchTmp.len) |i| {
        for(0..bunchTmp[i].bunch.len) |j| {
            bunchTmp[i].bunch[j] = null;
        }
        bunchTmp[i].flags.full = 0;
        bunchTmp[i].flags.lock = 0;
    }
    break :r struct { bunchs: [16]DriversBunch_T, last: usize } {
        .bunchs = bunchTmp,
        .last = 0,
    };
};

pub fn add(D: *const Driver_T) DriverErr_T!void {
    return if(D.major == null or D.ops == null) DriverErr_T.NullFound else r: {
        var bunch: usize = (D.major.? >> 2) & 0x07;
        var driver: usize = D.major.? & 0x03;
        t: {
            y: {
                if(driversBunch.bunchs[bunch].bunch[driver] != null) {
                    if(driversBunch.bunchs[bunch].bunch[driver].?.major.? == D.major.?) break :r DriverErr_T.MinorCollision;
                    break :y {};
                }
                if(!@as(bool, @bitCast(driversBunch.bunchs[bunch].flags.lock))) break :t {};
            }
            driversBunch.last = if(driversBunch.last >= driversBunch.bunchs.len) 0 else driversBunch.last;
            for(driversBunch.last..driversBunch.bunchs.len) |i| {
                y: {
                    if(@bitCast(driversBunch.bunchs[i].flags.full) or @bitCast(driversBunch.bunchs[i].flags.lock)) break :y {};
                    for(0..driversBunch.bunchs[i].bunch.len) |j| {
                        if(driversBunch.bunchs[i].bunch[j]) |_| continue;
                        if(driversBunch.bunchs[i].bunch.len - 1 == j) {
                            driversBunch.bunchs[i].flags.full = 1;
                            bunch, driver = .{ i, j }; break :t {};
                        }
                    }
                }
                driversBunch.last += 1;
            }
            break :r DriverErr_T.Blocked;
        }
        driversBunch.bunchs[bunch].bunch[driver] = @call(.never_inline, &Allocator.alloc, .{}) catch break :r DriverErr_T.InternalError;
        driversBunch.bunchs[bunch].bunch[driver].?.* = D.*; break :r {};
    };
}

pub fn del(M: MajorNum_T) DriverErr_T!void {
    return r: {
        var bunch: usize = (M >> 2) & 0x07;
        var driver: usize = M & 0x03;
        t: {
            y: {
                if(driversBunch.bunchs[bunch].bunch[driver] == null) break :y {};
                if(driversBunch.bunchs[bunch].bunch[driver].?.major == null) break :y {};
                if(driversBunch.bunchs[bunch].bunch[driver].?.major.? != M) break :y {};
                break :t {};
            }
            for(0..driversBunch.bunchs.len) |i| {
                for(0..driversBunch.bunchs[i].bunch.len) |j| {
                    if(
                        driversBunch.bunchs[i].bunch[j] != null and
                        driversBunch.bunchs[i].bunch[j].?.major != null and
                        driversBunch.bunchs[i].bunch[j].?.major.? == M
                    ) {
                        bunch, driver =  .{ i , j }; break :t {};
                    }
                }
            }
            break :r DriverErr_T.NoNFound;
        }
        @call(.never_inline, &Allocator.free, .{
            driversBunch.bunchs[bunch].bunch[driver].?
        }) catch break :r DriverErr_T.InternalError;
        driversBunch.bunchs[bunch].flags.full = 0; break :r {};
    };
}
