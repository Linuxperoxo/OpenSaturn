// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").core.fs;

pub const Fs: type = fs.Fs_T;
pub const FsErr: type = fs.FsErr_T;

pub const schfs = fs.schfs;
