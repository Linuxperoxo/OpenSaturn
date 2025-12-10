// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const fs: type = @import("root").core.fs;

pub const uid_T: type = if(@bitSizeOf(usize) >= 16) u16 else u8;
pub const gid_T: type = if(@bitSizeOf(usize) >= 32) u32 else uid_T;

pub const perm_T: type = packed struct(u3) {
    r: u1,
    w: u1,
    x: u1,
};

pub const mode_T: type = packed struct(u9) {
    owner: perm_T,
    group: perm_T,
    other: perm_T,
};

pub const FileType_T: type = enum {
    char,
    block,
    regular,
    directory,
    link,
};

pub const InodeOp_T: type = struct {
    read: ?*const fn(*Dentry_T) anyerror![]u8,
    write: ?*const fn(*Dentry_T, []const u8) anyerror!void,
    lookup: ?*const fn(*Dentry_T, []const u8) anyerror!*Dentry_T,
    mkdir: ?*const fn(*Dentry_T, []const u8, uid_T, gid_T, mode_T) anyerror!void,
    create: ?*const fn(*Dentry_T, []const u8, uid_T, gid_T, mode_T) anyerror!void,
    unlink: ?*const fn(*Dentry_T) anyerror!void,
    chmod: ?*const fn(*Dentry_T, mode_T) anyerror!void,
    chown: ?*const fn(*Dentry_T, uid_T, gid_T) anyerror!void,
    iterator: ?*const fn(*Dentry_T) []const *Dentry_T,
};

pub const Dentry_T: type = struct {
    d_name: []const u8,
    d_inode: ?*const Inode_T,
    d_sblock: ?*const Superblock_T,
    d_op: ?*const InodeOp_T,
    d_private: ?*const anyopaque,
    child: ?*@This(),
    younger_brother: ?*@This(),
    older_brother: ?*@This(),
    parent: ?*@This(),
    private: ?*anyopaque,
};

pub const Inode_T: type = struct {
    inode: usize, // numero do inode
    type: FileType_T, // tipo do arquivo
    uid: uid_T, // ID do usuario
    gid: gid_T, // ID do grupo
    mode: mode_T, // permissoes do arquivo
    nlinks: usize, // quantidade de links que apontam para esse inode
    data_block: usize, // aponta para qual bloco inicial estao os dados desse arquivo
    data_inode: usize, // aponta para o inode de dados (apenas para symlink)
};

pub const Superblock_T: type = struct {
    magic: u32, // flag magica
    block_size: usize, // tamanho em bytes de cada bloco do disco
    total_blocks: usize, // quantidade total de blocos disponiveis no dispositivo
    total_inodes: usize, // numero total de inodes disponiveis
    inode_table_start: usize, // offset(em blocos) de onde começa a tabela de inodes
    data_block_start: usize, // offset no disco onde começa a area de dados dos arquivos
    root_inode: *const Inode_T, // ponteiro para o inode raiz do sistema de arquivos
    inode_op: *const InodeOp_T, // ponteiro para operacoes do dentry montado
    fs: if(!builtin.is_test) *fs.Fs_T else void, // informacoes do fs montado no dentry
    private_data: ?*const anyopaque, // Dados internos do FS (cast dinamico)
};

pub const VfsErr_T: type = error {
    NoNFound,
    UnreachablePath,
    MountCollision,
    NoNMounted,
    ImpossiblePath,
    InodeAllocFailed,
    PathResolveError,
    AlreadyMounted,
    FilesystemMountError,
    NothingToUmount,
    InvalidOperation,
    OperationFailed,
    InvalidDentry,
};
