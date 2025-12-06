// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const fs: type = @import("root").core.fs;

pub const FileType_T: type = enum {
    char,
    block,
    directory,
    regular,
    link,
};

pub const InodeOp_T: type = struct {
    lookup: *const fn(*Dentry_T, []const u8) anyerror!*Dentry_T,
    mkdir: ?*fn(
        *Inode_T,
        []const u8,
        uid: u16,
        gid: u32,
        mode: u16
    ) anyerror!*Inode_T,
    create: ?*fn(
        *Inode_T,
        []const u8,
        uid: u16,
        gid: u32,
        mode: u16
    ) anyerror!*Inode_T,
    unlink: ?*fn(*Inode_T, []const u8) anyerror!void,
    iterator: ?*fn(*Inode_T) []const *Inode_T,
};

pub const Dentry_T: type = struct {
    d_name: []const u8,
    d_inode: ?*const Inode_T,
    d_sblock: ?*const Superblock_T,
    d_op: ?*const InodeOp_T,
    d_private: ?*const anyopaque,
    //fs: if(!builtin.is_test) ?*fs.interfaces.Fs_T else void = {},
    child: ?*@This(),
    brother: ?*@This(),
    parent: ?*@This(),
};

pub const Inode_T: type = struct {
    ino: usize, // Numero do inode
    type: FileType_T, // Tipo do arquivo
    uid: u16, // ID do usuario
    gid: u32, // ID do grupo
    mode: u16, // Permissoes do arquivo
    nlinks: u16, // Quantidade de links que apontam para esse inode
    data_block: usize, // Aponta para qual bloco inicial estao os dados desse arquivo
};

pub const Superblock_T: type = struct {
    magic: u32, // Flag magica
    block_size: usize, // Tamanho em bytes de cada bloco do disco
    total_blocks: usize, // Quantidade total de blocos disponiveis no dispositivo
    total_inodes: usize, // Numero total de inodes disponiveis
    inode_table_start: usize, // Offset(em blocos) de onde começa a tabela de inodes
    data_block_start: usize, // Offset no disco onde começa a area de dados dos arquivos
    root_inode: *Inode_T, // Ponteiro para o inode raiz do sistema de arquivos
    inode_op: *InodeOp_T,
    private_data: ?*anyopaque, // Dados internos do FS (cast dinamico)
};

pub const VfsErr_T: type = error {
    NoNFound,
    UnreachablePath,
    MountCollision,
    NoNMounted,
    ImpossiblePath,
    CorruptedTree,
    InodeAllocFailed,
    PathResolveError,
    AlreadyMounted,
    FilesystemMountError,
};
