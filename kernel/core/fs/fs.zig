// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const main: type = @import("main.zig");
const types: type = @import("types.zig");

pub const Fs_T: type = types.Fs_T;
pub const FsErr_T: type = types.FsErr_T;

pub const register_fs = main.register_fs;
pub const unregister_fs = main.unregister_fs;
pub const search_fs = main.search_fs;
