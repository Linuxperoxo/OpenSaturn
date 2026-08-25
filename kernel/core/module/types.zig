// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const arch: type = @import("root").interfaces.arch;
const fs: type = @import("root").interfaces.fs;
const devices: type = @import("root").interfaces.devices;
const hashtable: type = @import("root").lib.kernel.hash_table;
const modsys: type = @import("root").modsys;
const internal: type = @import("internal.zig");
const allocator: type = @import("allocator.zig");

pub const ModuleDescriptionTarget: type = arch.Target;
pub const Mods: type = hashtable.hashMap([]const u8, *ModInfo, null, null);

pub const ModuleDescriptionLoad: type = enum {
    linkable,
    dynamic,
    unlinkable
};

pub const Mod: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    deps: ?[]const []const u8 = null,
    license: ModLicense,
    type: ModType,
    init: *const fn() anyerror!void,
    exit: *const fn() anyerror!void,

    pub const insmod = internal.insmod;
    pub const rmmod = internal.rmmod;
    pub const updmod = internal.updmod;
    pub const depmod = internal.depmod;
};

pub const ModControlFlags: type = packed struct {
    anon: u1,
    init: u1,
    exit: u1,
    remove: u1,
};

pub const ModInfo: type = struct {
    module: *const Mod,
    running: bool,
    flags: ModControlFlags,

    pub inline fn builder(module: *const Mod, running: bool, flags: ModControlFlags) @This() {
        return @This() {
            .module = module,
            .running = running,
            .flags = flags,
        };
    }

    pub inline fn create(module: *const Mod, running: bool, flags: ModControlFlags) ModErr!*@This() {
        const ptr: *@This() = @ptrCast(allocator.sba.allocator.alloc(@This(), 1) catch return ModErr.ModuleAllocatorError);
        ptr.* = @This().builder(module, running, flags);
        return ptr;
    }

    pub inline fn destroy(self: *@This()) ModErr!void {
        return allocator.sba.allocator.free(self)
            catch ModErr.ModuleAllocatorError;
    }
};

pub const ModuleDescription: type = struct {
    mod: *const Mod,
    load: ModuleDescriptionLoad,
    insf: ModControlFlags,
    arch: []const ModuleDescriptionTarget, // arch suportadas
    c_sources: ?[]const[]const u8 = null,
    panic: bool = false,
    blacklist: ?[]const[]const u8 = null,
    libs: struct {
        mines: ?[]const ModuleDescriptionLibMine = null,
        outside: ?[]const ModuleDescriptionLibOut = null,
    } = .{},

    pub fn requestAll(comptime self: *const @This()) struct { [
        if(self.libs.outside == null) 0 else
            self.libs.outside.?.len
    ]?type, bool } {
        return comptime modsys.smll.searchAll(self);
    }

    pub fn requestLibs(comptime self: *const @This(), comptime libs: []const[]const u8) struct { [libs.len]?type, bool } {
        return comptime modsys.smll.searchLibs(self, libs);
    }

    pub fn requestLib(self: *const @This(), lib: []const u8) ?type {
        return comptime modsys.smll.searchLib(self, lib);
    }

    pub fn abortCompile(self: *const @This(), comptime msg: []const u8) noreturn {
        @compileError(self.name ++ ": " ++ msg);
    }
};

pub const ModuleDescriptionLibMine: type = struct {
    pub const Version: type = struct {
        tag: []const u8,
        lib: type,
        flags: packed struct {
            enable: u1,
        },
    };

    name: []const u8,
    whitelist: ?[]const []const u8,
    m_types: ?[]const ModType,
    current: comptime_int,
    stable: comptime_int,
    versions: []const Version,
    flags: packed struct {
        whitelist: u1, // usa whitelist
        enable: u1, // pode ser usada
    },
};

pub const ModuleDescriptionLibOut: type = struct {
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

pub const ModType: type = enum(u8) {
    driver,
    syscall,
    irq,
    filesystem,
};

pub const ModLicense: type = enum(u8) {
    gpl2_only,
    gpl2_or_later,
    gpl3_only,
    gpl3_or_later,
    bsd_2_clause,
    bsd_3_clause,
    mit,
    apache_2_0,
    proprietary,
};

pub const ModErr: type = error {
    NoNFound,
    ObsoleteDependency,
    ModuleAllocatorError,
    ModuleCollision,
    OperationDenied,
    InitFailed,
    ExitFailed,
    OperationFailed,
};
