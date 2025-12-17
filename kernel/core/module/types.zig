// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const list: type = @import("test/list.zig");
const arch: type = @import("root").interfaces.arch;
const fs: type = @import("root").interfaces.fs;
const modsys: type = @import("root").modsys;

// Interfaces

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
    license: ModLicense_T,
    type: ModType_T,
    deps: ?[]const []const u8,
    init: *const fn() anyerror!void,
    after: ?*const fn() anyerror!void,
    exit: *const fn() anyerror!void,
    private: union(ModType_T) {
        driver: void,
        syscall: void,
        irq: void,
        filesystem: if(!builtin.is_test) fs.Fs_T else void,
    },
    flags: packed struct {
        control: packed struct {
            anon: u1, // srchmod() nao expoe modulo
            call: packed struct {
                init: u1, // chama init logo no inmod()
                after: u1, // chama o after logo no inmod() apos chamada de init
                exit: u1, // chama exit logo no rmmod()
                remove: u1, // modulo aceita ser removido
                handler: packed struct {
                    install: u1,
                    remove: u1,
                },
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
                after: u1 = 0, // after foi chamado
                exit: u1 = 0, // exit foi chamado
                handler: packed struct {
                    install: u1 = 0,
                    remove: u1 = 0,
                } = .{},
            } = .{},
            fault: packed struct(u6) {
                remove: u1 = 0, // tentativa de remover o modulo que nao aceita ser removido
                // para saber se a operacao deu certo basta fazer
                // (control.call.init & internal.call.init & ~internal.fault.call.init) == 1
                call: packed struct {
                    init: u1 = 0, // init retornou erro
                    after: u1 = 0, // after retornou erro ou tentou ser chamado com ptr sendo null
                    exit: u1 = 0, // exit retornou erro
                    handler: packed struct {
                        install: u1 = 0,
                        remove: u1 = 0,
                    } = .{},
                } = .{},

                pub fn status(self: *const @This()) u6 {
                    return @as(*const u6, @alignCast(@ptrCast(self))).*;
                }
            } = .{},
        },

        pub inline fn check_op_status(self: *const @This(), comptime op: enum { init, after, exit, install, remove }) u1 {
            return switch (comptime op) {
                .init => self.control.call.init & self.internal.call.init & (~self.internal.fault.call.init),
                .after => self.control.call.after & self.internal.call.after & (~self.internal.fault.call.after),
                .exit => self.control.call.exit & self.internal.call.exit & (~self.internal.fault.call.exit),
                .install => self.control.call.handler.install & self.internal.call.handler.install & (~self.internal.fault.call.handler.install),
                .remove => self.control.call.handler.remove & self.internal.call.handler.remove & (~self.internal.fault.call.handler.remove),
            };
        }
    },
};

pub const ModType_T: type = enum(u2) {
    driver,
    syscall,
    irq,
    filesystem,
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

pub const ModLicense_T: type = union {
    know: enum {
        GPL2_only,
        GPL2_or_later,
        GPL3_only,
        GPL3_or_later,
        BSD_2_Clause,
        BSD_3_Clause,
        MIT,
        APACHE_2_0,
        PROPRIETARY,
    },
    other: []const u8,
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

pub const ModHandler_T: type = union(ModType_T) {
    driver: default_struct(null, null),
    syscall: default_struct(null, null),
    irq: default_struct(null, null),
    filesystem: default_struct(
        if(!builtin.is_test) *fs.Fs_T else null,
        if(!builtin.is_test) fs.FsErr_T else null,
    ),

    fn default_struct(comptime mod_struct: ?type, comptime mod_error: ?type) type {
        return if(mod_struct == null) void else struct {
            install: ?*const fn(mod_struct.?) if(mod_error != null) mod_error.?!void else anyerror!void,
            remove: ?*const fn(mod_struct.?) if(mod_error != null) mod_error.?!void else anyerror!void,
        };
    }
};

pub const ModuleDescriptionLibMine_T: type = struct {
    name: []const u8,
    whitelist: ?[]const []const u8,
    lib: type,
    flags: packed struct {
        whitelist: u1, // usa whitelist
        enable: u1, // pode ser usada
    },
    // versions: []type, TODO:
};

pub const ModuleDescriptionLibOut_T: type = struct {
    lib: []const u8,
    mod: []const u8,
};

pub const ModuleDescription_T: type = struct {
    name: []const u8,
    load: ModuleDescriptionLoad_T,
    init: *const fn() anyerror!void, // ponteiro para a funcao init
    after: ?*const fn() anyerror!void, // funcao executada apos init
    arch: []const ModuleDescriptionTarget_T, // arch suportadas
    deps: ?[]const[]const u8,
    libs: struct {
        mines: ?[]const ModuleDescriptionLibMine_T,
        outside: ?[]const ModuleDescriptionLibOut_T,
    },
    type: union(ModType_T) {
        driver: void,
        syscall: void,
        irq: void,
        filesystem: union(enum(u1)) {
            // faz a montagem de forma direta no kernel (fstab permanente)
            compile: struct {
                name: []const u8,
                mountpoint: []const u8,
            },
            dynamic: void, // sera adicionado ao kernel, mas sua montagem acontece em runtime
        },
    },
    flags: packed struct(u8) {
        call: packed struct {
            handler: u1, // chama handler responsavel pelo type do modulo, por exemplo, fs chama o handler fs
            after: u1, // chama funcao after, caso after seja null e essa flag seja 1, obtemos um erro em comptime
        },
        reserved: u6 = 0,
    },

    pub fn request_libs(self: *const @This()) anyerror!struct { [if(self.libs.outside != null) self.libs.outside.?.len else 0]?type, bool } {
        return comptime modsys.exposed.search_by_libs(self);
    }

    pub fn abort_compile(self: *const @This(), comptime msg: []const u8) noreturn {
        return comptime modsys.exposed.module_abort_compile(self, msg);
    }
};
