// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ops.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const MinorNum_T: type = @import("root").interfaces.device.MinorNum_T;

const Driver_T: type = @import("types.zig").Driver_T;
const DriverErr_T: type = @import("types.zig").DriverErr_T;
const Ops_T: type = @import("types.zig").Ops_T;
const OpsErr_T: type = @import("types.zig").OpsErr_T;
const MajorNum_T: type = @import("types.zig").MajorNum_T;

const Allocator: type = @import("allocator.zig");

// NOTE: Qualquer acesso ao major, deve passar pelo device, o devfs vai
// auxiliar qualquer acesso do userspace para um major, ele deve pegar o
// o device criado, buscar informacoes sobre ele usando seu minor, para criar
// um device no userspace vamos precisar de um minor obrigatoriamente, podemos
// passar um major tambem, mas nao deve ser obrigatorio. Depois disso, qualquer
// acesso ao dispositivo o devfs vai saber qual o seu minor, e assim consegue
// acessar seu major usando o minor.

pub fn open(M: MajorNum_T) DriverErr_T!void {

}

pub fn close(M: MajorNum_T) void {

}

pub fn minor(ma: MajorNum_T, mi: MinorNum_T) DriverErr_T!void {

}

pub fn read(M: MajorNum_T, offset: usize) []u8 {

}

pub fn write(M: MajorNum_T, data: []const u8) void {

}

pub fn ioctrl(M: MajorNum_T, command: usize, data: usize) OpsErr_T!usize {

}
