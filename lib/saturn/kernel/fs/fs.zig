// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").module;

pub const filesystemOP: type = struct {
    create: *fn([]const u8, u32) u8,
    expurg: *fn([]const u8) u8,
    mount: *fn([]const u8) u8,
    umount: *fn([]const u8) u8,
};

pub const filesystemFlags: type = struct {
    read: u1,
    write: u1,
    execute: u1,
};

pub const filesystem: type = struct {
    name: []const u8,
    flags: filesystemFlags,
    module: module.ModuleInterface,
    operation: filesystemOP,
};

pub const filesystemSuperBlock: type = struct {
    magic: u32,              // Identificador unico
    version: u32,            // Versão do FS
    block_size: u32,         // Tamanho de bloco
    total_blocks: u32,       // Total de blocos no FS
    total_inodes: u32,       // Total de inodes
    inode_table_start: u32,  // Bloco inicial da tabela de inodes
    data_block_start: u32,   // Bloco inicial de dados
    free_inode_bitmap: u32,  // Bloco com bitmap de inodes livres
    free_block_bitmap: u32,  // Bloco com bitmap de blocos livres
};

pub const filesystemError: type = error {
    NoNRegistered,
};

const fsRegisted: struct { fs: ?*filesystem, next: ?*filesystem } = .{
    .fs = null,
    .next = null,
};

fn cmpName(n0: []const u8, n1: []const u8) bool {
    const max: usize = if(n0.len < n1.len) n0.len else n1.len;
    var int: usize = 0;
    while(int < max) : (int += 1) {
        if(n0[int] != n1[int]) return false;
    }
    return true;
}

pub fn searchFilesystem(
    fs: []const u8
) filesystemError!*filesystem {
    var next: ?*@TypeOf(fsRegisted) = fsRegisted;
    while(next) |nextNoNNull| {
        if(nextNoNNull.fs) |nextFsNoNNull| { 
            if(@call(
                    .always_inline, 
                    &cmpName, 
                    .{
                        fs, 
                        nextFsNoNNull.name
                    }
                )) return nextFsNoNNull;
        }
        next = nextNoNNull.next;
    }
    return filesystemError.NoNRegistered;
}

pub fn registerFilesystem(
    fs: filesystem
) void {
    
}

pub fn unregisterFilesystem(
    fs: []const u8
) void {
    
}

