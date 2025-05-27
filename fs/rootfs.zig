// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: rootfs.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").fs;
const vfs: type = @import("root").fs.vfs;

const rootfs: fs.filesystem = .{
    .name = "rootfs",
    .flags = .{
        .creatable = 1,
        .purgeable = 1,
        .mountable = 1,
    },
    .module = .{
        .name = "rootfs",
        .desc = "Core Kernel Root Filesystem",
        .author = "Linuxperoxo",
        .version = "1.0-1",
        .type = .filesystem,
        .init = &init,
        .exit = &exit,
    },
    .operation = .{
        .create = &create,
        .expurg = &expurg,
        .mount = null,
        .umount = null,
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

const usr: *vfs.vfsEntry = &vfs.vfsEntry {
    .name = "usr",
    .inode = .{
        .type = .directory,
        .uid = @intCast(vfs.rootID),
        .gid = @intCast(vfs.rootGID),
        .mode = @intCast(vfs.rootMode),
        .hlink = 0,
    },
    .link = null,
    .mounted = null,
    .child = null,
    .brother = dev,
    .parent = vfs.rootDirectory,
};

// Dispositivos detectados e com drivers linkados
const dev: *vfs.vfsEntry = &vfs.vfsEntry {
    .name = "dev",
    .inode = .{
        .type = .directory,
        .uid = @intCast(vfs.rootID),
        .gid = @intCast(vfs.rootGID),
        .mode = @intCast(vfs.rootMode),
        .hlink = 0,
    },
    .link = null,
    .mounted = null,
    .child = null,
    .brother = proc,
    .parent = vfs.rootDirectory,
};

// Diretorio para montagem dos recursos do kernel
const sys: *vfs.vfsEntry = &vfs.vfsEntry {
    .name = "sys",
    .inode = .{
        .type = .directory,
        .uid = @intCast(vfs.rootID),
        .gid = @intCast(vfs.rootGID),
        .mode = @intCast(vfs.rootMode),
        .hlink = 0,
    },
    .link = null,
    .mounted = null,
    .child = proc,
    .brother = vrt,
    .parent = vfs.rootDirectory,
};

// Processos rodando
const proc: *vfs.vfsEntry = &vfs.vfsEntry {
    .name = "proc",
    .inode = .{
        .type = .directory,
        .uid = @intCast(vfs.rootID),
        .gid = @intCast(vfs.rootGID),
        .mode = @intCast(vfs.rootMode),
        .hlink = 0,
    },
    .link = null,
    .mounted = null,
    .child = null,
    .brother = sys,
    .parent = vfs.rootDirectory,
};

// Um diretorio de arquivos carregado em ram, em outras palavras, /tmp do linux
const vrt: *vfs.vfsEntry = &vfs.vfsEntry {
    .name = "virt",
    .inode = .{
        .type = .directory,
        .uid = @intCast(vfs.rootID),
        .gid = @intCast(vfs.rootGID),
        .mode = @intCast(vfs.rootMode),
        .hlink = 0,
    },
    .link = null,
    .mounted = null,
    .child = null,
    .brother = null,
    .parent = vfs.rootEntry,
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
    brother: ?*vfs.vfsEntry
) error{NonFound}!*vfs.vfsEntry {
    if(brother) |_| {
        var current: ?*vfs.vfsEntry = brother;
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
) error{NonFound}!*vfs.vfsEntry {
    var current: ?*vfs.vfsEntry = usr;
    var i: u32 = 0;
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

fn create(
    dentry: *const vfs.vfsEntry,
    name: []const u8,
    uid: u8,
    gid: u8,
    mode: u8,
) u8 {
    
}

fn expurg(
    entry: *const vfs.vfsEntry,
) u8 {

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
