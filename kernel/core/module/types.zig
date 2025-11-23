// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").interfaces.arch;

// Interfaces
pub const Mod_T: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    license: []const u8,
    type: ModType_T,
    init: *const fn() ModErr_T!void,
    exit: *const fn() ModErr_T!void,
    private: ?*anyopaque,
};

pub const ModType_T: type = enum {
    driver,
    syscall,
    interrupt,
    irq,
    filesystem,
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
    custom: []const u8,
};

pub const ModErr_T: type = error {
    IsInitialized,
    NoNInitialized,
    AllocatorError,
    InternalError,
};

pub const ModuleDescriptionTarget_T: type = arch.Target_T;

pub const ModuleDescription_T: type = struct {
    name: []const u8,
    load: enum { linkable, dinamic, unlinkable },
    init: *const fn() anyerror!void, // ponteiro para a funcao init
    arch: []const ModuleDescriptionTarget_T, // arch suportadas
    type: union(ModType_T) {
        driver: void,
        syscall: void,
        interrupt: void,
        irq: void,
        filesystem: union(enum) {
            compile: []const u8, // faz a montagem de forma direta no kernel (fstab permanente)
            dinamic: void, // sera adicionado ao kernel, mas sua montagem acontece em runtime
        },
    },
};

// Internal
pub const ModMajorStatus_T: type = enum {
    running,
    sleeping,
};

pub const ModMajor_T: type = struct {
    next: ?*@This(),
    status: ?ModMajorStatus_T,
    module: ?Mod_T,
};

pub const MajorInfo_T: type = struct {
    majors: ?*ModMajor_T,
    in: *const fn(*const Mod_T) ModErr_T!void,
    rm: *const fn(*const Mod_T) ModErr_T!void,
};
