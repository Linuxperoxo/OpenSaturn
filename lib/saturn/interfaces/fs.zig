// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").core.fs;

pub const Fs_T: type = fs.Fs_T;
pub const FsErr_T: type = fs.FsErr_T;

pub const register_fs = fs.register_fs;
pub const unregister_fs = fs.unregister_fs;
pub const search_fs = fs.search_fs;
