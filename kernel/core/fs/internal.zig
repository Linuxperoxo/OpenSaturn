// ┌───────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: types.zig     │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");

const Fs: type = types.Fs;
const FsErr: type = types.FsErr;
const FsInfo: type = types.FsInfo;
const FsControlFlags: type = types.FsControlFlags;
const FsKernelRegister: type = types.FsKernelRegister;

const kernel_fs: *FsKernelRegister = &@import("kernel_fs.zig").kernel_fs;

pub noinline fn regfs(fs: *const Fs, flags: FsControlFlags) FsErr!void {
    if(kernel_fs.testCollision(fs.name))
        return FsErr.FsCollision;

    kernel_fs.add(
        fs.name,
        try FsInfo.create(fs, flags),
        &allocator.sba.allocator
    ) catch return FsErr.FsRegisterFailed;
}

pub noinline fn unregfs(fs: *const Fs) FsErr!void {
    const fs_info: *FsInfo = kernel_fs.search(fs.name)
        catch return FsErr.NoNFound;

    kernel_fs.del(fs.name, &allocator.sba.allocator)
        catch return FsErr.FsUnregisterFailed;

    try fs_info.destroy();
}

pub noinline fn updfs(fs: *const Fs, flags: FsControlFlags) FsErr!void {
    (kernel_fs.search(fs.name)
        catch return FsErr.NoNFound).flags = flags;
}
