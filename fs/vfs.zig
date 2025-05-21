// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vfs.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").fs;

const vfs: fs.filesystem = .{
    .name = "vfs",
    .flags = .{
        // NOTE: Como o vfs e o sistema de arquivos mais basico do kernel, todas
        //       suas flags devem estar desativadas, e sua criaçao e remoçao de arquivos
        //       sera atravez de syscalls
        .creatable = 0,
        .purgeable = 0,
        .mountable = 0,
    },
    .module = .{
        .name = "vfs",
        .desc = "Kernel Core Virtual Filesystem",
        .author = "Linuxperoxo",
        .version = "1.0-1",
        .type = .filesystem,
        .init = &init,
        .exit = &exit,
    },
    .operation = .{
        .create = null,
        .expurg = null,
        .mount = null,
        .umount = null,
    }
};

pub const fileType: type = enum {
    directory,
    file,
    char,
    block,
    link,
};

pub const vfsInternal: type = struct {
    name: []const u8 = undefined, // Nome do arquivo
    type: fileType, // Tipo do arquivo
    uid: u8, // ID do usuario
    gid: u8, // ID do grupo
    mode: u9, // Permissoes do arquivo
    link: ?*vfsInternal, // Caso seja um link, esse sera o ponteiro para o arquivo virtual real
    mounted: *?fs.filesystem, // Sistema de arquivos montado, somente para diretorios
    child: ?*@This(), // Diretorio filho
    older_brother: ?*@This(), // Diretorio atras
    younger_brother: ?*@This(), // Diretorio frente
    parent: ?*@This(), // Diretorio pai
};

pub const rootID: comptime_int = 0;
pub const rootGID: comptime_int = 0;
pub const rootMode: comptime_int = 0b111101101;

const thisFile: type = @This();

pub const rootDirectory: *vfsInternal = &vfs {
    .name = "/",
    .type = .directory,
    .uid = @intCast(rootID),
    .gid = @intCast(rootGID),
    .mode = @intCast(rootMode),
    .link = null,
    .mounted = null,
    .child = null,
    .brother = null,
    .parent = thisFile.rootDirectory,
};

fn init() u8 {
    
}

fn exit() u8 {
    
}
