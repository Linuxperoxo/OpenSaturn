// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: rootfs.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").interfaces.fs;
const vfs: type = @import("root").core.vfs;

const rootfs: fs.filesystem = .{
    .name = "rootfs",
    .flags = .{
        .write = 0,
    },
    .mod = .{
        .name = "rootfs",
        .desc = "Core Kernel Root Filesystem",
        .author = "Linuxperoxo",
        .version = "1.0-1",
        .type = .filesystem,
        .init = &init,
        .exit = &exit,
    },
    .ops = .{
        .mount = .{ 
            .nodev = &rootfs_mount,
        },
        .umount = &rootfs_umount,
    },
};

// Hierarquia de arquivos de rootfs
// /
// ├── usr
// ├── dev
// ├── sys
// │   └── proc
// └── vrt

// A estrutura do saturn e bem parecida com o unix em geral
// uma diferença de arquitetura escolhida por mim e que o root(/)
// na verdade nao e a montagem do disco realmente, e sim toda a estrutura
// do kernel, o / do linux vai fica em /usr e todo o root fica carregado na 
// ram, somente o /usr fica em disco, mas tambem pretendo fazer o /usr ser um
// sistema de arquivos carregado em ram com programas basico do sistema carregados

const rootfs_branch: type = struct {
    dentry: *vfs.Dentry,
    brother: ?*rootfs_branch,
    child: ?*rootfs_branch,
    parent: ?*rootfs_branch
};

const rootfsErr: type = error {
    NonFound,
};

fn makeDefaultsDirectories(
    name: []const u8,
    ino: u32,
    brother: ?*rootfs_branch,
    child: ?*rootfs_branch,
    parent: ?*rootfs_branch,
    private: *rootfs_branch
) *rootfs_branch {
    return &rootfs_branch {
        .dentry = &vfs.Dentry {
            .name = name,
            .inode = &vfs.Inode {
                .ino = ino,
                .type = .directory,
                .uid = 0,
                .gid = 0,
                .mode = 0b111101101,
                .nlinks = 0,
                .data_block = 0,
                .private = private,
                .ops = &vfs.InodeOP {
                    .lookup = &rootfs_lookup,
                    .mkdir = &rootfs_mkdir,
                    .create = &rootfs_create,
                    .unlink = &rootfs_unlink,
                },
            },
        },
        .brother = brother,
        .child = child,
        .parent = parent,
    };
}

const @"/": *rootfs_branch        = @call(.compile_time, &makeDefaultsDirectories, .{
    "/",    // Inode Name
    0,      // Inode number
    null,   // Brother
    @"usr", // Child
    @"/",   // Parent
    @"/"    // Private
});
const @"usr": *rootfs_branch      = @call(.compile_time, &makeDefaultsDirectories, .{
    "usr",
    1,
    @"sys",
    null,
    @"/",
    @"usr"
});
const @"sys": *rootfs_branch      = @call(.compile_time, &makeDefaultsDirectories, .{
    "sys",
    2,
    @"dev",
    null,
    @"/",
    @"sys"
});
const @"dev": *rootfs_branch      = @call(.compile_time, &makeDefaultsDirectories, .{
    "dev",
    3,
    @"volatile",
    null,
    @"/",
    @"dev"
});
const @"volatile": *rootfs_branch = @call(.compile_time, &makeDefaultsDirectories, .{
    "volatile",
    4,
    null,
    null,
    @"/",
    @"volatile"
});

const rootfs_superblock: *vfs.Superblock = &vfs.Superblock {
    .magic = 0x703,
    .block_size = 0,
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_table_start = 0,
    .data_block_start = 0,
    .root_inode = @"/".dentry.inode,
    .private_data = @"/",
};

fn rootfs_mount() rootfsErr!*vfs.Superblock {
    return rootfs_superblock;
}

fn rootfs_umount() void {
    // Como e um sistema de arquivos em ram, devemos
    // liberar qualquer memoria aqui
}

fn cmp_name(
    noalias s0: []const u8,
    noalias s1: []const u8
) bool {
    if(s0.len != s1.len) {
        return false;
    }
    for(0..s0.len) |i| {
        if(s0[i] != s1[i]) {
            return false;
        }
    }
    return true;
}

fn rootfs_lookup(
    parent: *vfs.Dentry,
    name: []const u8
) rootfsErr!*vfs.Dentry {
    var current: ?*rootfs_branch = block0: {
        if(parent.inode) |NoNNullInode| {
            break :block0 NoNNullInode.private;
        }
        break :block0 null;
    };
    while(current) |NoNNullCurrent| {
        if(@call(.always_inline, &cmp_name, .{
            NoNNullCurrent.dentry.name,
            name
        })) {
            return NoNNullCurrent.dentry;
        }
        current = NoNNullCurrent.brother;
    }
    return rootfsErr.NonFound;
}

fn rootfs_mkdir(
    parent: *vfs.Dentry,
    name: []const u8,
    uid: u16,
    gid: u32,
    mode: u16,
) rootfsErr!*vfs.Dentry {
    
}

fn rootfs_create(
    parent: *vfs.Dentry,
    name: []const u8,
    uid: u16,
    gid: u32,
    mode: u16,
) rootfsErr!*vfs.Dentry {
    
}

fn rootfs_unlink(
    parent: *vfs.Dentry,
    name: []const u8,
) rootfsErr!void {
    
}

fn init() u32 {
    @call(
        .never_inline,
        &fs.registerFilesystem,
        .{
            rootfs
        }
    );
}

fn exit() u32 {
    @call(
        .never_inline,
        &fs.unregisterFilesystem,
        .{
            rootfs.name
        }
    );
}
