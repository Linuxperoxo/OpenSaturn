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

pub const ModErr_T: type = error {
    IsInitialized,
    NoNInitialized,
    AllocatorError,
    InternalError,
};

pub const ModuleDescriptionTarget_T: type = arch.target_T;

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
