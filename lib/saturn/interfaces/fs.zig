// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").core.fs;
const interfaces: type = fs.interfaces;
const memory: type = fs.memory;

pub const Fs_T: type = interfaces.Fs_T;
pub const FsMnt_T: type = interfaces.FsMnt_T;
pub const FsErr_T: type = interfaces.FsErr_T;

pub const registerfs: fn(Fs_T) FsErr_T!usize = interfaces.registerfs;
pub const unregisterfs: fn([]const u8) FsErr_T!usize = interfaces.unregisterfs;
pub const searchfs: fn([]const u8) FsErr_T!Fs_T = interfaces.searchfs;
// TODO: pub const alloc: fn() void;
