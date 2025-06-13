// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").vfs;
const module: type = @import("root").interfaces.module;

pub const fsmnt_T = struct {
    mount: union(u1) {
        dev: *fn(dev: []const u8) anyerror!*vfs.Superblock,
        nodev: *fn() anyerror!*vfs.Superblock,
    },
    umount: *fn() void,
};

pub const fs_T: type = struct {
    name: []const u8,
    flags: struct {write: u1},
    mod: module.Module_T,
    mount: fsmnt_T,
};

pub const fserr_T: type = error {
    NoNRegistered,
};

const fsRegisted: struct { fs: ?*fs_T, next: ?*fs_T } = .{
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

pub fn searchfs(
    fs: []const u8
) fserr_T!*fs_T {
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
    return fserr_T.NoNRegistered;
}

pub fn registerfs(
    fs: fs_T
) void {
    
}

pub fn unregisterfs(
    fs: []const u8
) void {
    
}

