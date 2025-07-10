// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Vfs: type = @import("root").core.vfs;
const Module: type = @import("root").interfaces.module;

const Mod_T: type = @import("root").core.module.interfaces.Mod_T;
const Superblock: type = @import("root").core.vfs.interfaces.Superblock_T;

pub const FsFlags_T: type = enum(u2) {
    W,
    R,
    RW,
};

pub const Fs_T: type = struct {
    name: []const u8,
    flags: FsFlags_T,
    mount: *fn() FsErr_T!Vfs.interfaces.Superblock_T,
    unmount: *fn() FsErr_T!void,
};

pub const FsErr_T: type = error {
    NoNRegistered, // searchfs pode retornar isso
    DoubleFree, // tentar usar unregisterfs em um fs nao registrado
    Rewritten, // tentativa de registrar um fs ja registrado
    AllocInternal, // erro na alocaçao de memoria
    InternalError, // erro interno no gerenciador de fs 
};

pub const registerfs = @import("management.zig").registerfs;
pub const unregisterfs = @import("management.zig").unregisterfs;

// NOTE: Alocador temporario
pub const Allocator: type = @import("root").memory;
