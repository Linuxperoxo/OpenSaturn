// ┌────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: extern.zig     │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");

const Fs_T: type = types.Fs_T;
const FsErr_T: type = types.FsErr_T;
const FsInfo_T: type = types.FsInfo_T;
const FsControlFlags_T: type = types.FsControlFlags_T;
const FsKernelRegister_T: type = types.FsKernelRegister_T;

const kernel_fs: *FsKernelRegister_T = &@import("kernel_fs.zig").kernel_fs;

pub fn schfs(fs_name: []const u8) FsErr_T!*Fs_T {
    const fs_info: *FsInfo_T = kernel_fs.search(fs_name)
        catch return FsErr_T.NoNFound;

    return if(fs_info.flags.anon == 1) FsErr_T.NoNFound else
        @constCast(fs_info.fs);
}
