// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").core.fs;
const interfaces: type = fs.interfaces;
const memory: type = fs.memory;

pub const Fs_T: type = interfaces.Fs_T;
pub const FsErr_T: type = interfaces.FsErr_T;

pub const registerfs = interfaces.registerfs;
pub const unregisterfs= interfaces.unregisterfs;
pub const alloc = interfaces.alloc;
pub const free = interfaces.free;
