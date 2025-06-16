// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const vfs: type = @import("root").core.vfs;
const module: type = @import("root").interfaces.module;

pub const FsMnt_T = struct {
    mount: union(u1) {
        dev: *fn(dev: []const u8) anyerror!*vfs.Superblock,
        nodev: *fn() anyerror!*vfs.Superblock,
    },
    umount: *fn() void,
};

pub const Fs_T: type = struct {
    name: []const u8,
    flags: struct {write: u1},
    mod: module.Module_T,
    mount: FsMnt_T,
};

pub const FsErr_T: type = error {
    NoNRegistered, // searchfs pode retornar isso
    DoubleFree, // tentar usar unregisterfs em um fs nao registrado
    Rewritten, // tentativa de registrar um fs ja registrado
};

const loadedfs: struct {fs: ?*Fs_T, next: ?*Fs_T} = .{
    .fs = null,
    .next = null,
};

pub fn searchfs(
    name: []const u8
) FsErr_T!Fs_T {

}

pub fn registerfs(
    fs: Fs_T
) FsErr_T!usize {
    
}

pub fn unregisterfs(
    name: []const u8
) FsErr_T!usize {
    
}
