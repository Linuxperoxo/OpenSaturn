// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const list: type = @import("test/list.zig");
const arch: type = @import("root").interfaces.arch;
const fs: type = @import("root").interfaces.fs;
const devices: type = @import("root").interfaces.devices;
const modsys: type = @import("root").modsys;
const hashtable: type = @import("root").lib.utils.hashtable;
const internal: type = @import("internal.zig");

pub const ModuleDescriptionTarget_T: type = arch.Target_T;
pub const Mods_T: type = hashtable.buildHashTable([]const u8, *ModInfo_T, null, null);

pub const ModuleDescriptionLoad_T: type = enum {
    linkable,
    dynamic,
    unlinkable
};

pub const Mod_T: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    deps: ?[]const []const u8 = null,
    license: ModLicense_T,
    type: ModType_T,
    init: *const fn() anyerror!void,
    exit: *const fn() anyerror!void,

    pub const insmod = internal.insmod;
    pub const rmmod = internal.rmmod;
    pub const updmod = internal.updmod;
};

pub const ModControlFlags_T: type = packed struct {
    anon: u1,
    init: u1,
    exit: u1,
    remove: u1,
};

pub const ModInfo_T: type = struct {
    module: *const Mod_T,
    running: bool,
    flags: ModControlFlags_T,
};

pub const ModuleDescription_T: type = struct {
    mod: *const Mod_T,
    load: ModuleDescriptionLoad_T,
    insf: ModControlFlags_T,
    arch: []const ModuleDescriptionTarget_T, // arch suportadas
    c_sources: ?[]const[]const u8 = null,
    panic: bool = false,
    blacklist: ?[]const[]const u8 = null,
    libs: struct {
        mines: ?[]const ModuleDescriptionLibMine_T = null,
        outside: ?[]const ModuleDescriptionLibOut_T = null,
    } = .{},

    pub fn request_all(comptime self: *const @This()) struct { [
        if(self.libs.outside == null) 0 else
            self.libs.outside.?.len
    ]?type, bool } {
        return comptime modsys.smll.search_all(self);
    }

    pub fn request_libs(comptime self: *const @This(), comptime libs: []const[]const u8) struct { [libs.len]?type, bool } {
        return comptime modsys.smll.search_libs(self, libs);
    }

    pub fn request_lib(self: *const @This(), lib: []const u8) ?type {
        return comptime modsys.smll.search_lib(self, lib);
    }

    pub fn abort_compile(self: *const @This(), comptime msg: []const u8) noreturn {
        @compileError(self.name ++ ": " ++ msg);
    }
};

pub const ModuleDescriptionLibMine_T: type = struct {
    pub const Version_T: type = struct {
        tag: []const u8,
        lib: type,
        flags: packed struct {
            enable: u1,
        },
    };

    name: []const u8,
    whitelist: ?[]const []const u8,
    m_types: ?[]const ModType_T,
    current: comptime_int,
    stable: comptime_int,
    versions: []const Version_T,
    flags: packed struct {
        whitelist: u1, // usa whitelist
        enable: u1, // pode ser usada
    },
};

pub const ModuleDescriptionLibOut_T: type = struct {
    lib: []const u8,
    mod: []const u8,
    version: union(enum) {
        tag: []const u8,
        current: void,
        stable: void,
    },
    flags: packed struct {
        // * 0 => lib pode retornar null caso o modulo nao seja encontrado ou a propria lib
        // * 1 => sempre vai retornar a lib, caso nao encontre o modulo ou a lib um erro de compilacao acontece
        required: u1,
    },
};

pub const ModType_T: type = enum(u8) {
    driver,
    syscall,
    irq,
    filesystem,
};

pub const ModLicense_T: type = enum(u8) {
    GPL2_only,
    GPL2_or_later,
    GPL3_only,
    GPL3_or_later,
    BSD_2_Clause,
    BSD_3_Clause,
    MIT,
    APACHE_2_0,
    PROPRIETARY,
};

pub const ModErr_T: type = error {
    NoNFound,
    ObsoleteDependency,
    AllocatorError,
    ModuleCollision,
    OperationDenied,
    InitFailed,
    ExitFailed,
    OperationFailed,
};
