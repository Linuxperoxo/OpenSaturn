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
    regular,
    char,
    block,
    link,
};

pub const InodeOP: type = struct {
    lookup: fn(parent: *Dentry, name: []const u8) ?*Dentry,
    mkdir: fn(parent: *Dentry, name: []const u8) error{}!*Dentry,
    create: fn(parent: *Dentry, name: []const u8) error{}!*Dentry,
    unlink: fn(parent: *Dentry, name: []const u8) error{}!void,
    readlink: ?fn(node: *Dentry) []const u8,
};

pub const Inode: type = struct {
    ino: u32, // Numero do inode
    type: fileType, // Tipo do arquivo
    uid: u8, // ID do usuario
    gid: u8, // ID do grupo
    mode: u9, // Permissoes do arquivo
    nlinks: u16, // Quantidade de links que apontam para esse inode
    data_block: u32, // Aponta para qual bloco inicial estao os dados desse arquivo 
    ops: *InodeOP, // Operaçoes para esse inode
};

pub const Dentry: type = struct {
    name: []const u8, // Nome do arquivo/diretorio
    inode: ?*Inode, // Inode associado
    parent: ?*Dentry, // Pai
    child: ?*Dentry, // Primeiro filho
    brother: ?*Dentry, // Irmao
    mounted_fs: ?*fs.filesystem, // Sistema de arquivos montado
};

pub const Superblock: type = struct {
    magic: u32, // Flag magica
    block_size: u32, // Tamanho em bytes de cada bloco do disco
    total_blocks: u32, // Quantidade total de blocos disponiveis no dispositivo
    total_inodes: u32, // Numero total de inodes disponiveis
    inode_table_start: u32, // Offset(em blocos) de onde começa a tabela de inodes
    data_block_start: u32, // Offset no disco onde começa a area de dados dos arquivos
    root_inode: *Inode, // Ponteiro para o inode raiz do sistema de arquivos
    private_data: ?*anyopaque, // Dados internos do FS (cast dinamico)
};

const rootID: comptime_int = 0;
const rootGID: comptime_int = 0;
const rootMode: comptime_int = 0b111101101;

const root: *Dentry = &Dentry {
    .name = "/",
    .inode = null,
    .parent = root,
    .child = null,
    .brother = null,
    .mounted_fs = null,
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
    var i: u32 = 0;
    var current: ?*Dentry = block0: {
        if(path[i] == '/' and path.len == 1) {
            return root;
        }
        break :block0 root.child;
    };
    while(i < path.len) : (i += 1) {
        if(path[i] == '/') {
            i += 1;
            if(i >= path.len) {
                return error.NonFound;
            }
        }
        const savedI: u32 = i;
        while(i < path.len and path[i] != '/') : (i += 1) {}
        current = @call(
            .always_inline,
            &findBrotherRecursion,
            .{
                path[savedI..i],
                current
            }
        ) catch {
            return error.NonFound;
        };
        if(i < path.len - 1 and path[i] == '/') {
            current = current.?.child;
        }
    }
    return current.?;
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
