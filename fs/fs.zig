// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const vfs: type = @import("vfs.zig");
pub const devfs: type = @import("devfs.zig");

pub const VirtualFilesType: type = union(enum(u1)) {
    device: *devfs.DeviceFilesystem,
    inode: *Inode,
};

pub const InodeTypes: type = enum(u1) {
    file,
    dir,
};

pub const Inode: type = struct {
    root: u32 = 0,
    continuation: u32 = 0,
    type: InodeTypes,
    size: u32 = 0,
    blocks: u32 = 0,
    child: u32,
    brother: u32,
    parent: u32,
};

pub const VirtualFile: type = struct {
    name: [:0]const u8 = undefined,
    file: VirtualFilesType,
    uid: u8,
    gid: u8,
    mode: u9,
    child: ?*anyopaque,
    brother: ?*anyopaque,
    parent: ?*anyopaque,
};

const rootUID: comptime_int = 0;
const rootGID: comptime_int = 0;
const rootMode: comptime_int = 0b111101101; // rwxr-xr-x

const root: VirtualFile = .{
    .name = [_:0]u8{"/"},
    .file = .{ .inode = &Inode {} },
    .uid = @intCast(rootUID),
    .gid = @intCast(rootGID),
    .mode = @intCast(rootMode),
    .child = null,
    .brother = null,
    .parent = &root,
};

var currentDir: *VirtualFile = &root;

pub fn mkdev(file: *const [:0]u8, device: devfs.DeviceFilesystem) void {
    
}

pub fn rmdev(file: *const [:0]u8) void {
    
}

pub fn mkfile(file: VirtualFile) void {

}

pub fn mkdir(file: VirtualFile) void {

}



