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

pub const ModuleDescriptionTarget_T: type = arch.Target_T;

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
    private: union(ModType_T) {
        driver: if(!builtin.is_test) *devices.Dev_T else void,
        syscall: void,
        irq: void,
        filesystem: if(!builtin.is_test) *fs.Fs_T else void,
    },
    flags: packed struct {
        control: packed struct {
            anon: u1, // srchmod() nao expoe modulo
            call: packed struct {
                init: u1, // chama init logo no inmod()
                after: u1, // chama o after logo no inmod() apos chamada de init
                exit: u1, // chama exit logo no rmmod()
                remove: u1, // modulo aceita ser removido
            },
        },
        internal: packed struct {
            installed: u1 = 0, // foi instalado
            removed: u1 = 0, // foi removido
            collision: packed struct {
                name: u1 = 0, // nomes iguais
                pointer: u1 = 0, // ponteiros iguais (double reg)
            } = .{},
            call: packed struct {
                init: u1 = 0, // init foi chamado
                exit: u1 = 0, // exit foi chamado
            } = .{},
            fault: packed struct {
                remove: u1 = 0, // tentativa de remover o modulo que nao aceita ser removido
                // para saber se a operacao deu certo basta fazer
                call: packed struct {
                    init: u1 = 0, // init retornou erro
                    exit: u1 = 0, // exit retornou erro
                } = .{},
            } = .{},
        } = .{},
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

pub const ModFoundByType_T: type = enum(u2) {
    name = 0b01,
    pointer = 0b10,
};

pub const ModRoot_T: type = struct {
    list: list.BuildList(*Mod_T),
    type: ModType_T,
    flags: packed struct(u8) {
        init: u1,
        reserved: u7 = 0,
    },
};

pub const ModErr_T: type = error {
    SectionHandlerError,
    NoNFound,
    IteratorFailed,
    ListInitFailed,
    AllocatorError,
    ListOperationError,
    RemovedButWithHandlerError,
    ModuleCollision,
    OperationDenied,
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

pub const ModuleDescription_T: type = struct {
    name: []const u8,
    load: ModuleDescriptionLoad_T,
    init: *const fn() anyerror!void, // ponteiro para a funcao init
    arch: []const ModuleDescriptionTarget_T, // arch suportadas
    deps: ?[]const[]const u8 = null,
    c_sources: ?[]const[]const u8 = null,
    type: ModType_T,
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
