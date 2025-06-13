// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: syscalls.zig │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").interfaces.fs;

pub fn registerfs(
    FS: fs.fs_T
) void {
    // syscall
}

pub fn unregisterfs(
    name: []const u8
) void {
    // syscall
}

