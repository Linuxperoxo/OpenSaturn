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
    dentry: ?*vfs.Dentry,
    next: ?*rootfs_branch,
};

fn makeDefaultsDirectories(
    name: []const u8,
    ino: u32,
    next: ?*rootfs_branch
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
                .ops = &vfs.InodeOP {
                    .lookup = &rootfs_lookup,
                    .mkdir = &rootfs_mkdir,
                    .create = &rootfs_create,
                    .unlink = &rootfs_unlink,
                },
            },
        },
        .next = next,
    };
}

const @"usr": *rootfs_branch = @call(.compile_time, &makeDefaultsDirectories, .{"usr", 1, @"sys"});
const @"sys": *rootfs_branch = @call(.compile_time, &makeDefaultsDirectories, .{"sys", 2, @"dev"});
const @"dev": *rootfs_branch = @call(.compile_time, &makeDefaultsDirectories, .{"dev", 2, @"volatile"});
const @"volatile": *rootfs_branch = @call(.compile_time, &makeDefaultsDirectories, .{"volatile", 2, null});

const rootfs_superblock: *vfs.Superblock = &vfs.Superblock {
    .magic = 0x703,
    .block_size = 0,
    .total_blocks = 0,
    .total_inodes = 0,
    .inode_table_start = 0,
    .data_block_start = 0,
    .root_inode = &vfs.Inode {
        .ino = 0,
        .type = .directory,
        .uid = 0,
        .gid = 0,
        .mode = 0b111101101,
        .nlinks = 0,
        .data_block = 0,
        .ops = &vfs.InodeOP {
            .lookup = &rootfs_lookup,
            .mkdir = &rootfs_mkdir,
            .create = &rootfs_create,
            .unlink = &rootfs_unlink,
        },
    },
    .private_data = @"usr",
};

fn rootfs_mount() rootfsErr!*vfs.Superblock {
    return rootfs_superblock;
}

fn rootfs_umount() void {
    // Como e um sistema de arquivos em ram, devemos
    // liberar qualquer memoria aqui
}

fn rootfs_lookup(
    parent: *vfs.Dentry,
    name: []const u8
) rootfsErr!*vfs.Dentry {
    
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

const rootfsErr: type = error {

};

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
