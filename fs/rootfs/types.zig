// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
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
// └── volatile

// A estrutura do saturn e bem parecida com o unix em geral
// uma diferença de arquitetura escolhida por mim e que o root(/)
// na verdade nao e a montagem do disco realmente, e sim toda a estrutura
// do kernel, o / do linux vai fica em /usr e todo o root fica carregado na 
// ram, somente o /usr fica em disco, mas tambem pretendo fazer o /usr ser um
// sistema de arquivos carregado em ram com programas basico do sistema carregados

pub const RootfsBranch_T: type = struct {
    dentry: ?*Dentry_T,
    brother: ?*RootfsBranch_T,
    child: ?*RootfsBranch_T,
    parent: ?*RootfsBranch_T
};

pub const RootfsErr_T: type = error {
    NonFound,
};

