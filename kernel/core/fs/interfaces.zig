// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const vfs: type = @import("root").core.vfs;
const module: type = @import("root").interfaces.module;

const Mod_T: type = @import("root").core.module.interfaces.Mod_T;
const Superblock: type = @import("root").core.vfs.interfaces.Superblock_T;

pub const FsMnt_T = struct {
    mount: union(u1) {
        dev: *fn(dev: []const u8) anyerror!*Superblock,
        nodev: *fn() anyerror!*Superblock,
    },
    umount: *fn() void,
};

pub const Fs_T: type = struct {
    name: []const u8,
    flags: struct {write: u1},
    mod: Mod_T,
    mount: FsMnt_T,
};

pub const FsErr_T: type = error {
    NoNRegistered, // searchfs pode retornar isso
    DoubleFree, // tentar usar unregisterfs em um fs nao registrado
    Rewritten, // tentativa de registrar um fs ja registrado
};
