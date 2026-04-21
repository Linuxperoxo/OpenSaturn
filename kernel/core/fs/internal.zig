// ┌───────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: types.zig     │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");

const Fs_T: type = types.Fs_T;
const FsErr_T: type = types.FsErr_T;
const FsInfo_T: type = types.FsInfo_T;
const FsControlFlags_T: type = types.FsControlFlags_T;
const FsKernelRegister_T: type = types.FsKernelRegister_T;

const kernel_fs: *FsKernelRegister_T = &@import("kernel_fs.zig").kernel_fs;

pub noinline fn regfs(fs: *const Fs_T, flags: FsControlFlags_T) FsErr_T!void {
    if(kernel_fs.test_collision(fs.name))
        return FsErr_T.FsCollision;

    kernel_fs.add(
        fs.name,
        try FsInfo_T.create(fs, flags),
        &allocator.sba.allocator
    ) catch return FsErr_T.FsRegisterFailed;
}

pub noinline fn unregfs(fs: *const Fs_T) FsErr_T!void {
    const fs_info: *FsInfo_T = kernel_fs.search(fs.name)
        catch return FsErr_T.NoNFound;

    kernel_fs.del(fs.name, &allocator.sba.allocator)
        catch return FsErr_T.FsUnregisterFailed;

    try fs_info.destroy();
}

pub noinline fn updfs(fs: *const Fs_T, flags: FsControlFlags_T) FsErr_T!void {
    (kernel_fs.search(fs.name)
        catch return FsErr_T.NoNFound).flags = flags;
}
