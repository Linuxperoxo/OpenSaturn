// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Fs_T: type = @import("root").interfaces.fs.Fs_T;
const FsErr_T: type = @import("root").interfaces.fs.FsErr_T;

const fsRegisted: struct { fs: ?*Fs_T, next: ?*Fs_T } = .{
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

pub fn searchfs(
    name: []const u8
) FsErr_T!*Fs_T {
    var next: ?*@TypeOf(fsRegisted) = fsRegisted;
    while(next) |nextNoNNull| {
        if(nextNoNNull.fs) |nextFsNoNNull| { 
            if(@call(
                    .always_inline, 
                    &cmpName, 
                    .{
                        name,
                        nextFsNoNNull.name
                    }
                )) return nextFsNoNNull;
        }
        next = nextNoNNull.next;
    }
    return fs.fserr_T.NoNRegistered;
}

pub fn registerfs(
    fs: Fs_T
) FsErr_T!usize {
    
}

pub fn unregisterfs(
    name: []const u8
) FsErr_T!usize {
    
}
