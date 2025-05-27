// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vfs.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").fs;
const module: type = @import("root").module;
// TODO: Criaçao de interfaces para incluir novos syscalls em tempo
//       de execuçao
// const syscalls: type = @import("root").syscalls;

// Nosso virtual filesystem vai servir somente para aplicar
// syscalls para controle de arquivos, quem realmente vai fazer
// a parte bruta vai ser o modulo de systema de arquivos chamado rootfs,
// ele e o pai de todos os sistemas de arquivos carregador no kernel

const vfsmod: module.ModuleInterface = .{
    .name = "vfs",
    .desc = "Kernel Core Virtual Filesystem",
    .author = "Linuxperoxo",
    .version = "1.0-1",
    .type = .syscall,
    .init = &init,
    .exit = &exit,
};

pub const fileType: type = enum {
    directory,
    file,
    char,
    block,
    link,
};

pub const fileInode: type = struct {
    type: fileType, // Tipo do arquivo
    uid: u8, // ID do usuario
    gid: u8, // ID do grupo
    mode: u9, // Permissoes do arquivo
    hlink: u16, // Quantidade de links que apontam para esse arquivo
};

pub const vfsEntry: type = struct {
    name: []const u8 = undefined, // Nome do arquivo
    inode: fileInode,
    link: ?*vfsEntry, // Caso seja um link, esse sera o ponteiro para o arquivo virtual real
    mounted: *?fs.filesystem, // Sistema de arquivos montado, somente para diretorios
    child: ?*@This(), // Diretorio filho
    brother: ?*@This(), // Diretorio/Arquivo frente
    parent: ?*@This(), // Diretorio pai
};

const rootID: comptime_int = 0;
const rootGID: comptime_int = 0;
const rootMode: comptime_int = 0b111101101;

const root: *vfsEntry = &vfsEntry {
    .name = "/",
    .inode = .{
        .type = .directory,
        .uid = @intCast(rootID),
        .gid = @intCast(rootGID),
        .mode = @intCast(rootMode),
        .hlink = 0,
    },
    .link = null,
    .mounted = null,
    .child = null,
    .brother = null,
    .parent = root,
};

fn sys_chdir() void {
}

fn sys_mkdir() void {

}

fn sys_rmdir() void {

}

fn sys_chmod() void {

}

fn sys_chown() void {

}

fn sys_link() void {

}

fn sys_unlink() void {

}

fn init() u8 {
    
}

fn exit() u8 {
    
}
