// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ops.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Core: type = @import("core.zig");

const Driver_T: type = @import("types.zig").Driver_T;
const DriverErr_T: type = @import("types.zig").DriverErr_T;
const Ops_T: type = @import("types.zig").Ops_T;
const OpsErr_T: type = @import("types.zig").OpsErr_T;
const MajorNum_T: type = @import("types.zig").MajorNum_T;
const MinorNum_T: type = @import("types.zig").MinorNum_T;

const Allocator: type = @import("allocator.zig");

const search = struct {
    pub fn search(major: MajorNum_T) DriverErr_T!*Driver_T {
        return @call(.always_inline, &Core.search, .{
            major
        });
    }
};

// NOTE: Qualquer acesso ao major, deve passar pelo device, o devfs vai
// auxiliar qualquer acesso do userspace para um major, ele deve pegar o
// o device criado, buscar informacoes sobre ele usando seu minor, para criar
// um device no userspace vamos precisar de um minor obrigatoriamente, podemos
// passar um major tambem, mas nao deve ser obrigatorio. Depois disso, qualquer
// acesso ao dispositivo o devfs vai saber qual o seu minor, e assim consegue
// acessar seu major usando o minor.

pub fn open(Major: MajorNum_T, Minor: MajorNum_T) DriverErr_T!void {
    const major: *Driver_T = @call(.never_inline, &search, .{
        Major
    }) catch |err| return err;
    return if(major.ops.open) |_| major.ops.open.?(Minor) else DriverErr_T.Unreachable;
}

pub fn close(Major: MajorNum_T, Minor: MinorNum_T) void {
    const major: *Driver_T = @call(.never_inline, &search, .{
        Major
    }) catch |err| return err;
    return if(major.ops.close) |_| major.ops.close.?(Minor) else DriverErr_T.Unreachable;
}

pub fn minor(Major: MajorNum_T, Minor: MinorNum_T) DriverErr_T!void {
    return (@call(.never_inline, &search, .{
        Major
    })).ops.minor.*(Minor);
}

pub fn read(Major: MajorNum_T, Minor: MinorNum_T, offset: usize) []u8 {
    return (@call(.never_inline, &search, .{
        Major
    })).ops.read.*(Minor, offset);
}

pub fn write(Major: MajorNum_T, Minor: MinorNum_T, data: []const u8) void {
    return (@call(.never_inline, &search, .{
        Major
    })).ops.write.*(Minor, data);
}

pub fn ioctrl(Major: MajorNum_T, Minor: MinorNum_T, command: usize, data: usize) OpsErr_T!usize {
    return (@call(.never_inline, &search, .{
        Major
    })).ops.ioctrl.*(Minor, command, data);
}
