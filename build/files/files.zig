// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: files.zig      │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const root: type = @import("../../build.zig");

pub const ArchFiles_T: type = @import("types.zig").ArchFiles_T;
pub const ArchFileInfo_T: type = @import("types.zig").ArchFileInfo_T;
pub const ArchRelativeFiles_T: type = @import("types.zig").ArchRelativeFiles_T;

const __SaturnSupervisorFeature__ = root.SaturnArchInfo.__SaturnEnabledArchSupervisor__;
const __SaturnTarget__ = root.SaturnArchInfo.__SaturnTarget__;

pub const archFilesInfo: ArchFiles_T = .{
    .linker = .{
        .base = "linkers",
        .file = "linker.ld",
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
    .linker = archFilesInfo.linker.base ++ "/" ++ @tagName(__SaturnTarget__) ++ "/" ++ archFilesInfo.linker.file,
    .libk = archFilesInfo.libk.base ++ "/" ++ @tagName(__SaturnTarget__) ++ "/" ++ archFilesInfo.libk.file,
    .libs = archFilesInfo.libs.base ++ "/" ++ @tagName(__SaturnTarget__) ++ "/" ++ archFilesInfo.libs.file,
    .interrupt = i: {
        if(__SaturnSupervisorFeature__) {
            break :i archFilesInfo.interrupt.base ++ "/" ++ @tagName(__SaturnTarget__) ++ "/" ++ "supervisor" ++ "/" ++ archFilesInfo.interrupt.file;
        }
        break :i archFilesInfo.interrupt.base ++ "/" ++ @tagName(__SaturnTarget__) ++ "/" ++ archFilesInfo.interrupt.file;
    },
};
