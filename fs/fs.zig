// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const vfs: type = @import("vfs.zig");
pub const devfs: type = @import("devfs.zig");
pub const rootfs: type = @import("rootfs.zig");

const module: type = @import("root").module;

pub const filesystemOP: type = struct {
    iterator: ?*fn(*const vfs.vfsEntry) u8,
    create: ?*fn(*const vfs.vfsEntry, []const u8, u8, u8,) u8,
    expurg: ?*fn(*const vfs.vfsEntry, []const u8) u8,
    mount: ?*fn(u8) u8,
    umount: ?*fn() u8,
};

// Flags que seram usadas pelo vfs para controlar
// operaçoes entre diferentes tipos de sistema de
// arquivos
pub const filesystemFlags: type = struct {
    creatable: u1,
    purgeable: u1,
    mountable: u1,
};

pub const filesystem: type = struct {
    name: []const u8,
    flags: filesystemFlags,
    module: module.ModuleInterface,
    operation: filesystemOP,
};

const fsRegisted: struct { fs: ?*filesystem, next: ?*filesystem } = .{
    .fs = null,
    .next = null,
};

fn cmpName(
    n0: []const u8,
    n1: []const u8
) bool {
    const max: usize = if(n0.len < n1.len) n0.len else n1.len;
    var int: usize = 0;
    while(int < max) : (int += 1) {
        if(n0[int] != n1[int]) return false;
    }
    return true;
}

pub fn searchFilesystem(fs: []const u8) error{NonRegistered}!*filesystem {
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
    return error.NonRegistered;
}

pub fn registerFilesystem(fs: filesystem) void {
    
}

pub fn unregisterFilesystem(fs: []const u8) void {
    
}


