// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

// VFS
const Dentry_T: type = @import("root").core.vfs.interfaces.Dentry_T;
const Superblock_T: type = @import("root").core.vfs.interfaces.Superblock_T;
const FileType_T: type = @import("root").core.vfs.interfaces.FileType_T;
const InodeOp_T: type = @import("root").core.vfs.interfaces.InodeOp_T;
const Inode_T: type = @import("root").core.vfs.interfaces.Inode_T;
const VfsErr_T: type = @import("root").core.vfs.interfaces.VfsErr_T;

// Module
const Mod_T: type = @import("root").interfaces.module.Mod_T;

// FS
const Fs_T: type = @import("root").interfaces.fs.Fs_T;

const TreeBranch_T: type = struct {
    entry: *?Dentry_T, // Entry desse ramo
    mounted_fs: ?*Fs_T, // Sistema de arquivos montado aqui(Somente para diretorios)
    sb: ?*Superblock_T, // Ponteiro para o superbloco do fs
    parent: ?*TreeBranch_T, // Entry pai
    child: ?*TreeBranch_T,  // Entry filho
    brother: ?*TreeBranch_T, // Entry irmao
};

const vfsMod: Mod_T = .{
    .name = "vfs",
    .desc = "Kernel Core Virtual Filesystem",
    .author = "Linuxperoxo",
    .version = "1.1",
    .type = .syscall,
    .init = &init,
    .exit = &exit,
};

const root: TreeBranch_T = .{
    .entry = &Dentry_T {
        .name = "/",
        .inode = null,
    },
    .mounted_fs = null,
    .sb = null,
    .parent = &root,
    .brother = null,
    .child = null,
};

fn TheseFileNamesIsEqual(
    n0: []const u8,
    n1: []const u8
) bool {
    if(n0.len != n1.len) return false;
    var i: usize = 0;
    while(i < n0.len) :
        (i += 1) {
        if(n0[i] != n1[i]) return false;
    }
    return true;
}

fn findBrotherRecursion(
    name: []const u8,
    brother: ?*Dentry_T
) VfsErr_T!*Dentry_T {
    if(brother) |_| {
        var current: ?*Dentry_T = brother;
        while(current) |_| : 
            (current = current.?.brother) {
            if(@call(
                .always_inline, 
                &TheseFileNamesIsEqual,
                .{
                    current.?.name,
                    name
                })) {
                return current.?;
            }
        }
    }
    return VfsErr_T.NoNFound;
}

fn resolvePath(
    path: []const u8
) VfsErr_T!*Dentry_T {
    // TODO: Fazer toda a logica para resolver o caminho
    //       indo diretorio por diretorio e usar o lookup
    //       de cada fs para procurar o arquivo que queremos
    //       
    //       EXEMPLO: /sys/proc/proc0
    //       
    //       1: Perguntar ao sistema de arquivo montado em / se o sys existe
    //       2: Caso o / retorne o sys, vamos perguntar para o sistema de arquivos
    //          montado em sys se existe o proc, e assim por diante ate chegar no proc0
    //       
    //       OBS: A funçao lookup do sistema de arquivos e a responsavel por fazer o retorno
    //            do arquivo que queremos em um certo diretorio, ela deve receber o nome do arquivo
    //            como um []const u8, e o dentry pai dessa arquivo, digamos que queremos achar o proc
    //            o dentry pai dele e o sys

    _ = path;
}

fn init() usize {

}

fn exit() usize {

}
