// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fs.zig       │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");

pub const Fs: type = types.Fs;
pub const FsErr: type = types.FsErr;

pub const schfs = @import("extern.zig").schfs;
