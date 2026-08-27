// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const fs: type = @import("root").core.fs;
const drivers: type = @import("root").core.drivers;

pub const Uid: type = if(@bitSizeOf(usize) >= 16) u16 else u8;
pub const Gid: type = if(@bitSizeOf(usize) >= 32) u32 else Uid;

pub const r: u3 = 0b100;
pub const w: u3 = 0b010;
pub const x: u3 = 0b001;

pub const Mode: type = packed struct(u9) {
    owner: u3,
    group: u3,
    other: u3,
};

pub const FileType: type = enum {
    char,
    block,
    regular,
    directory,
    link,
};

pub const InodeOp: type = struct {
    read: ?*const fn(*Dentry, usize) anyerror![]u8 = null,
    write: ?*const fn(*Dentry, []const u8, usize) anyerror!void = null,
    lookup: ?*const fn(*Dentry, []const u8) anyerror!*Dentry = null,
    mkdir: ?*const fn(*Dentry, []const u8, Uid, Gid, Mode) anyerror!void = null,
    create: ?*const fn(*Dentry, []const u8, Uid, Gid, Mode) anyerror!void = null,
    unlink: ?*const fn(*Dentry) anyerror!void = null,
    chmod: ?*const fn(*Dentry, Mode) anyerror!void = null,
    chown: ?*const fn(*Dentry, Uid, Gid) anyerror!void = null,
    iterator: ?*const fn(*Dentry) []const *Dentry = null,
    ioctl: ?*const fn(*Dentry, usize, *anyopaque) anyerror!usize = null,
};

pub const Dentry: type = struct {
    d_name: []const u8,
    d_inode: ?*Inode,
    d_sblock: ?*Superblock,
    d_op: ?*InodeOp,
    d_private: ?*anyopaque,
    child: ?*@This(),
    younger_brother: ?*@This(),
    older_brother: ?*@This(),
    parent: ?*@This(),
};

pub const Inode: type = struct {
    inode: usize, // numero do inode
    type: FileType, // tipo do arquivo
    uid: Uid, // ID do usuario
    gid: Gid, // ID do grupo
    mode: Mode, // permissoes do arquivo
    nlinks: usize, // quantidade de links que apontam para esse inode
    data_block: usize, // aponta para qual bloco inicial estao os dados desse arquivo
    data_inode: usize, // aponta para o inode de dados (apenas para symlink)
};

pub const Superblock: type = struct {
    magic: u32, // flag magica
    block_size: usize, // tamanho em bytes de cada bloco do disco
    total_blocks: usize, // quantidade total de blocos disponiveis no dispositivo
    total_inodes: usize, // numero total de inodes disponiveis
    inode_table_start: usize, // offset(em blocos) de onde começa a tabela de inodes
    data_block_start: usize, // offset no disco onde começa a area de dados dos arquivos
    inode_op: *InodeOp, // ponteiro para operacoes do dentry montado
    fs: *fs.Fs, // informacoes do fs montado no dentry
    private_data: ?*anyopaque, // Dados internos do FS (cast dinamico)
};

pub const VfsErr: type = error {
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
    WithoutParent,
};
