// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");

pub const Fs_T: type = types.Fs_T;
pub const FsErr_T: type = types.FsErr_T;

pub const schfs = @import("extern.zig").schfs;
