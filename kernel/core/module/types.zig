// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const list: type = @import("test/list.zig");
const arch: type = @import("root").interfaces.arch;
const fs: type = @import("root").interfaces.fs;

// Interfaces
pub const Mod_T: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    license: ModLicense_T,
    type: ModType_T,
    deps: ?[]const []const u8,
    init: *const fn() ModErr_T!void,
    exit: *const fn() ModErr_T!void,
    private: union(ModType_T) {
        driver: void,
        syscall: void,
        irq: void,
        filesystem: if(!builtin.is_test) fs.Fs_T else void,
    },
};

pub const ModType_T: type = enum(u2) {
    driver,
    syscall,
    irq,
    filesystem,
};

pub const ModRoot_T: type = struct {
    list: list.BuildList(*const Mod_T),
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

pub const ModuleDescriptionTarget_T: type = arch.Target_T;

pub const ModuleDescription_T: type = struct {
    name: []const u8,
    load: enum { linkable, dinamic, unlinkable },
    init: *const fn() anyerror!void, // ponteiro para a funcao init
    arch: []const ModuleDescriptionTarget_T, // arch suportadas
    deps: ?[]const[]const u8,
    type: union(ModType_T) {
        driver: void,
        syscall: void,
        irq: void,
        filesystem: union(enum(u1)) {
            compile: []const u8, // faz a montagem de forma direta no kernel (fstab permanente)
            dinamic: void, // sera adicionado ao kernel, mas sua montagem acontece em runtime
        },
    },
};
