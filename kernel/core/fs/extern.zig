// ┌────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: extern.zig     │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");

const Fs: type = types.Fs;
const FsErr: type = types.FsErr;
const FsInfo: type = types.FsInfo;
const FsControlFlags: type = types.FsControlFlags;
const FsKernelRegister: type = types.FsKernelRegister;

const kernel_fs: *FsKernelRegister = &@import("kernel_fs.zig").kernel_fs;

pub fn schfs(fs_name: []const u8) FsErr!*Fs {
    const fs_info: *FsInfo = kernel_fs.search(fs_name)
        catch return FsErr.NoNFound;

    return if(fs_info.flags.anon == 1) FsErr.NoNFound else
        @constCast(fs_info.fs);
}
