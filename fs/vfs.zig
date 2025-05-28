// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vfs.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").fs;
const module: type = @import("root").module;
// TODO: Criaçao de interfaces para incluir novos syscalls em tempo
//       de execuçao
// const syscalls: type = @import("root").syscalls;

// Nosso virtual filesystem vai servir somente para aplicar
// syscalls para controle de arquivos, quem realmente vai fazer
// a parte bruta vai ser o modulo de systema de arquivos chamado rootfs,
// ele e o pai de todos os sistemas de arquivos carregador no kernel

const vfsmod: module.ModuleInterface = .{
    .name = "vfs",
    .desc = "Kernel Core Virtual Filesystem",
    .author = "Linuxperoxo",
    .version = "1.0-1",
    .type = .syscall,
    .init = &init,
    .exit = &exit,
};

pub const fileType: type = enum {
    directory,
    regular,
    char,
    block,
    link,
};

pub const fileInode: type = struct {
    type: fileType, // Tipo do arquivo
    uid: u8, // ID do usuario
    gid: u8, // ID do grupo
    mode: u9, // Permissoes do arquivo
    hlink: u16, // Quantidade de links que apontam para esse arquivo
};

pub const vfsEntry: type = struct {
    name: []const u8 = undefined, // Nome do arquivo
    inode: fileInode,
    link: ?*vfsEntry, // Caso seja um link, esse sera o ponteiro para o arquivo virtual real
    mounted: *?fs.filesystem, // Sistema de arquivos montado, somente para diretorios
    child: ?*@This(), // Diretorio filho
    brother: ?*@This(), // Diretorio/Arquivo frente
    parent: ?*@This(), // Diretorio pai
};

const rootID: comptime_int = 0;
const rootGID: comptime_int = 0;
const rootMode: comptime_int = 0b111101101;

const root: *vfsEntry = &vfsEntry {
    .name = "/",
    .inode = .{
        .type = .directory,
        .uid = @intCast(rootID),
        .gid = @intCast(rootGID),
        .mode = @intCast(rootMode),
        .hlink = 0,
    },
    .link = null,
    .mounted = null,
    .child = null,
    .brother = null,
    .parent = root,
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
    brother: ?*vfsEntry
) error{NonFound}!*vfsEntry {
    if(brother) |_| {
        var current: ?*vfsEntry = brother;
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
) error{NonFound}!*vfsEntry {
    var i: u32 = 0;
    var current: ?*vfsEntry = block0: {
        if(path[i] == '/' and path.len == 1) {
            return root;
        }
        break :block0 root.child;
    };
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

fn sys_chdir() void {
}

fn sys_mkdir() void {

}

fn sys_rmdir() void {

}

fn sys_chmod() void {

}

fn sys_chown() void {

}

fn sys_link() void {

}

fn sys_unlink() void {

}

fn init() u8 {
    
}

fn exit() u8 {
    
}
