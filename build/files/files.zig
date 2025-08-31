// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: files.zig      │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const root: type = @import("../../build.zig");

const ArchFiles_T: type = @import("types.zig").ArchFiles_T;
const ArchFileInfo_T: type = @import("types.zig").ArchFileInfo_T;
const ArchRelativeFiles_T: type = @import("types.zig").ArchRelativeFiles_T;

pub const archFilesInfo: ArchFiles_T = .{
    .linker = .{
        .base = "linkers",
        .file = @tagName(root.SaturnArchConfig.options.Target) ++ "_linker.ld",
    },

    .libk = .{
        .base = "lib/saturn/kernel",
        .file = "lib.zig",
    },

    .libs = .{
        .base = "lib/saturn/userspace",
        .file = "lib.zig",
    },

    .interrupt = .{
        .base = "kernel/interrupts",
        .file = "interrupts.zig",
    },
};

pub const archResolvedFiles: ArchRelativeFiles_T = .{
    .linker = archFilesInfo.linker.base ++ "/" ++ @tagName(root.SaturnArchConfig.options.Target) ++ "/" ++ archFilesInfo.linker.file,
    .libk = archFilesInfo.libk.base ++ "/" ++ @tagName(root.SaturnArchConfig.options.Target) ++ "/" ++ archFilesInfo.libk.file,
    .libs = archFilesInfo.libs.base ++ "/" ++ @tagName(root.SaturnArchConfig.options.Target) ++ "/" ++ archFilesInfo.libs.file,
    .interrupt = archFilesInfo.interrupt.base ++ "/" ++ @tagName(root.SaturnArchConfig.options.Target) ++ "/" ++ archFilesInfo.interrupt.file,
};
