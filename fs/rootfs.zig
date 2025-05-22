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
        .mountable = 0,
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

// NOTE: A estrutura do saturn e bem parecida com o unix em geral
//       uma diferença de arquitetura escolhida por mim e que o root(/)
//       na verdade nao e a montagem do disco realmente, e sim toda a estrutura
//       do kernel, o / do linux vai fica em /usr e todo o root fica carregado na 
//       ram, somente o /usr fica em disco, mas tambem pretendo fazer o /usr ser um
//       sistema de arquivos carregado em ram com programas basico do sistema carregados

// NOTE: root do sistema
const usr: *vfs.vfsInternal = &vfs.vfsInternal {
    .name = "usr",
    .type = .directory,
    .uid = @intCast(vfs.rootID),
    .gid = @intCast(vfs.rootGID),
    .mode = @intCast(vfs.rootMode),
    .link = null,
    .mounted = null,
    .child = null,
    .older_brother = usr,
    .younger_brother = dev,
    .parent = vfs.rootDirectory,
};

// NOTE: dispositivos detectados
const dev: *vfs.vfsInternal = &vfs.vfsInternal {
    .name = "dev",
    .type = .directory,
    .uid = @intCast(vfs.rootID),
    .gid = @intCast(vfs.rootGID),
    .mode = @intCast(vfs.rootMode),
    .link = null,
    .mounted = null,
    .child = null,
    .older_brother = usr,
    .younger_brother = proc,
    .parent = vfs.rootDirectory,
};

// NOTE: processos rodando
const proc: *vfs.vfsInternal = &vfs.vfsInternal {
    .name = "proc",
    .type = .directory,
    .uid = @intCast(vfs.rootID),
    .gid = @intCast(vfs.rootGID),
    .mode = @intCast(vfs.rootMode),
    .link = null,
    .mounted = null,
    .child = null,
    .older_brother = dev,
    .younger_brother = sys,
    .parent = vfs.rootDirectory,
};

// NOTE: informaçoes do sistema
const sys: *vfs.vfsInternal = &vfs.vfsInternal {
    .name = "sys",
    .type = .directory,
    .uid = @intCast(vfs.rootID),
    .gid = @intCast(vfs.rootGID),
    .mode = @intCast(vfs.rootMode),
    .link = null,
    .mounted = null,
    .child = null,
    .older_brother = proc,
    .younger_brother = vir,
    .parent = vfs.rootDirectory,
};

// NOTE: um sistema de arquivos carregado em ram, em outras palavras, /tmp do linux
const vir: *vfs.vfsInternal = &vfs.vfsInternal {
    .name = "vir",
    .type = .directory,
    .uid = @intCast(vfs.rootID),
    .gid = @intCast(vfs.rootGID),
    .mode = @intCast(vfs.rootMode),
    .link = null,
    .mounted = null,
    .child = null,
    .older_brother = sys,
    .younger_brother = null,
    .parent = vfs.rootDirectory,
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
    brother: ?*vfs.vfsInternal
) error{NonFound}!*vfs.vfsInternal {
    if(brother) |_| {
        var current: ?*vfs.vfsInternal = brother;
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
) error{NonFound}!*vfs.vfsInternal {
    var current: ?*vfs.vfsInternal = usr;
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
    file: []const u8,
    flags: u32
) u8 {
    
}

fn expurg(
    file: []const u8
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
