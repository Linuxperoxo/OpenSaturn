// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: rootfs.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Dentry_T: type = @import("root").core.vfs.interfaces.Dentry_T;
const Superblock_T: type = @import("root").core.vfs.interfaces.Superblock_T;
const Inode_T: type = @import("root").core.vfs.interfaces.Inode_T;

// Hierarquia de arquivos de rootfs
// /
// ├── usr
// ├── dev
// ├── sys
// │   └── proc
// └── volatile

// A estrutura do saturn e bem parecida com o unix em geral
// uma diferença de arquitetura escolhida por mim e que o root(/)
// na verdade nao e a montagem do disco realmente, e sim toda a estrutura
// do kernel, o / do linux vai fica em /usr e todo o root fica carregado na 
// ram, somente o /usr fica em disco, mas tambem pretendo fazer o /usr ser um
// sistema de arquivos carregado em ram com programas basico do sistema carregados

pub const RootfsBranch_T: type = struct {
    dentry: *Dentry_T,
    brother: ?*RootfsBranch_T,
    child: ?*RootfsBranch_T,
    parent: ?*RootfsBranch_T
};

pub const RootfsErr_T: type = error {
    NonFound,
};

fn makeDefaultsDirectories(
    name: []const u8,
    ino: u32,
    brother: ?*RootfsBranch_T,
    child: ?*RootfsBranch_T,
    parent: ?*RootfsBranch_T,
    private: *RootfsBranch_T,
) *RootfsBranch_T {
    return &RootfsBranch_T {
        .dentry = &Dentry_T {
            .name = name,
            .inode = &Inode_T {
                .ino = ino,
                .type = .directory,
                .uid = 0,
                .gid = 0,
                .mode = 0b111101101,
                .nlinks = 0,
                .data_block = 0,
                .private = private,
                .ops = null,
            },
        },
        .brother = brother,
        .child = child,
        .parent = parent,
    };
}

pub const @"/": *RootfsBranch_T        = @call(.compile_time, &makeDefaultsDirectories, .{
    "/",    // Inode Name
    0,      // Inode number
    null,   // Brother
    @"usr", // Child
    @"/",   // Parent
    @"/"    // Private
});
pub const @"usr": *RootfsBranch_T      = @call(.compile_time, &makeDefaultsDirectories, .{
    "usr",
    1,
    @"sys",
    null,
    @"/",
    @"usr"
});
pub const @"sys": *RootfsBranch_T      = @call(.compile_time, &makeDefaultsDirectories, .{
    "sys",
    2,
    @"dev",
    null,
    @"/",
    @"sys"
});
pub const @"dev": *RootfsBranch_T      = @call(.compile_time, &makeDefaultsDirectories, .{
    "dev",
    3,
    @"volatile",
    null,
    @"/",
    @"dev"
});
pub const @"volatile": *RootfsBranch_T = @call(.compile_time, &makeDefaultsDirectories, .{
    "volatile",
    4,
    null,
    null,
    @"/",
    @"volatile"
});

pub const rootfsSuperblock: *Superblock_T = &Superblock_T {
    .magic = 0x703,
    .block_size = 0,
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_table_start = 0,
    .data_block_start = 0,
    .root_inode = @"/".dentry.inode,
    .private_data = @"/",
};
