// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").vfs;
const module: type = @import("root").module;

pub const filesystemOP = struct {
    mount: fn(dev: []const u8) error{}!vfs.Superblock,
    umount: fn(sb: *vfs.Superblock) void,
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

