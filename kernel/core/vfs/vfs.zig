// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vfs.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").interfaces.fs;
const module: type = @import("root").interfaces.module;

// TODO: Criaçao de interfa para incluir novos syscalls em tempo
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
    regular,
    char,
    block,
    link,
};

pub const InodeOP: type = struct {
    // Responsavel por fazer a resoluçao de arquivos, 
    // arquivos ja resolvidos uma vez serao colocados na arvore
    // do vfs
    lookup: *fn(
        parent: *Dentry, 
        name: []const u8
    ) anyerror!*Dentry,

    // Responsavel por criar um novo diretorio
    mkdir: *fn(
        parent: *Dentry, 
        name: []const u8,
        uid: u16,
        gid: u32,
        mode: u16
    ) anyerror!*Dentry,

    // Responsavel por criar um novo arquivo
    create: *fn(
        parent: *Dentry, 
        name: []const u8, 
        uid: u16, 
        gid: u32, 
        mode: u16
    ) anyerror!*Dentry,

    // Responsavel por criar um novo link simbolico
    // TODO: link: *fn()

    // Responsavel por resolver links simbolicos
    // TODO: readlink: *fn(node: *Dentry) anyerror!*Dentry,

    // Responsavel por remover um arquivo
    unlink: *fn(
        parent: *Dentry, 
        name: []const u8
    ) anyerror!void,

    // Responsavel por listar os arquivos de um diretorio
    interator: *fn(
            parent: *Dentry,
    ) []const *Dentry,
};

const TreeBranch: type = struct {
    entry: *?Dentry, // Entry desse ramo
    mounted_fs: ?*fs.filesystem, // Sistema de arquivos montado aqui(Somente para diretorios)
    sb: ?*Superblock, // Ponteiro para o superbloco do fs
    parent: ?*TreeBranch, // Entry pai
    child: ?*TreeBranch,  // Entry filho
    brother: ?*TreeBranch, // Entry irmao
};

pub const Inode: type = struct {
    ino: u32, // Numero do inode
    type: fileType, // Tipo do arquivo
    uid: u16, // ID do usuario
    gid: u32, // ID do grupo
    mode: u16, // Permissoes do arquivo
    nlinks: u16, // Quantidade de links que apontam para esse inode
    data_block: u32, // Aponta para qual bloco inicial estao os dados desse arquivo 
    private: ?*anyopaque, // Dados internos do FS
    ops: ?*InodeOP, // Operaçoes para esse inode
};

pub const Dentry: type = struct {
    name: []const u8, // Nome do arquivo/diretorio
    inode: ?*Inode, // Inode associado
};

pub const Superblock: type = struct {
    magic: u32, // Flag magica
    block_size: u32, // Tamanho em bytes de cada bloco do disco
    total_blocks: u32, // Quantidade total de blocos disponiveis no dispositivo
    total_inodes: u32, // Numero total de inodes disponiveis
    inode_table_start: u32, // Offset(em blocos) de onde começa a tabela de inodes
    data_block_start: u32, // Offset no disco onde começa a area de dados dos arquivos
    root_inode: ?*Inode, // Ponteiro para o inode raiz do sistema de arquivos
    private_data: ?*anyopaque, // Dados internos do FS (cast dinamico)
};

const rootBranch: TreeBranch = .{
    .entry = &Dentry {
        .name = "/",
        .inode = null,
    },
    .mounted_fs = null,
    .sb = null,
    .parent = rootBranch,
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
    brother: ?*Dentry
) error{NonFound}!*Dentry {
    if(brother) |_| {
        var current: ?*Dentry = brother;
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
    return error.NonFound;
}

fn resolvePath(
    path: []const u8
) error{NonFound}!*Dentry {
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
}

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
