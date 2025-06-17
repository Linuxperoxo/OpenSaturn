// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const FileType_T: type = enum {
    char,
    block,
    directory,
    regular,
    link,
};

pub const InodeOp_T: type = struct {
    // Responsavel por fazer a resoluçao de arquivos, 
    // arquivos ja resolvidos uma vez serao colocados na arvore
    // do vfs
    lookup: *fn(
        parent: *Dentry_T, 
        name: []const u8
    ) anyerror!*Dentry_T,

    // Responsavel por criar um novo diretorio
    mkdir: *fn(
        parent: *Dentry_T, 
        name: []const u8,
        uid: u16,
        gid: u32,
        mode: u16
    ) anyerror!*Dentry_T,

    // Responsavel por criar um novo arquivo
    create: *fn(
        parent: *Dentry_T, 
        name: []const u8, 
        uid: u16, 
        gid: u32, 
        mode: u16
    ) anyerror!*Dentry_T,

    // Responsavel por criar um novo link simbolico
    // TODO: link: *fn()

    // Responsavel por resolver links simbolicos
    // TODO: readlink: *fn(node: *Dentry) anyerror!*Dentry,

    // Responsavel por remover um arquivo
    unlink: *fn(
        parent: *Dentry_T,
        name: []const u8
    ) anyerror!void,

    // Responsavel por listar os arquivos de um diretorio
    interator: *fn(
            parent: *Dentry_T,
    ) []const *Dentry_T,
};

pub const Inode_T: type = struct {
    ino: u32, // Numero do inode
    type: FileType_T, // Tipo do arquivo
    uid: u16, // ID do usuario
    gid: u32, // ID do grupo
    mode: u16, // Permissoes do arquivo
    nlinks: u16, // Quantidade de links que apontam para esse inode
    data_block: u32, // Aponta para qual bloco inicial estao os dados desse arquivo 
    private: ?*anyopaque, // Dados internos do FS
    ops: ?*InodeOp_T, // Operaçoes para esse inode
};

pub const Dentry_T: type = struct {
    name: []const u8, // Nome do arquivo/diretorio
    inode: ?*Inode_T, // Inode associado
};

pub const Superblock_T: type = struct {
    magic: u32, // Flag magica
    block_size: u32, // Tamanho em bytes de cada bloco do disco
    total_blocks: u32, // Quantidade total de blocos disponiveis no dispositivo
    total_inodes: u32, // Numero total de inodes disponiveis
    inode_table_start: u32, // Offset(em blocos) de onde começa a tabela de inodes
    data_block_start: u32, // Offset no disco onde começa a area de dados dos arquivos
    root_inode: ?*Inode_T, // Ponteiro para o inode raiz do sistema de arquivos
    private_data: ?*anyopaque, // Dados internos do FS (cast dinamico)
};

pub const VfsErr_T: type = error {
    NoNFound,
};
