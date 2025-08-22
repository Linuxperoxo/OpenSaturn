// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const ArchFiles_T: type = struct {
    linker: ArchFileInfo_T,
    libk: ArchFileInfo_T,
    libs: ArchFileInfo_T,
    interrupt: ArchFileInfo_T,
};

pub const ArchFileInfo_T: type = struct {
    base: []const u8,
    file: []const u8,
};

pub const ArchRelativeFiles_T: type = struct {
    linker: []const u8,
    libk: []const u8,
    libs: []const u8,
    interrupt: []const u8,
};

