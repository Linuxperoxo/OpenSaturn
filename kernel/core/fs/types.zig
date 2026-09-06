// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig     │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const vfs: type = @import("root").core.vfs;
const hashtable: type = @import("root").lib.kernel.hash_table;
const internal: type = @import("internal.zig");
const allocator: type = @import("allocator.zig");

pub const Fs: type = struct {
    name: []const u8,
    mount: *const fn(src: []const u8) anyerror!*const vfs.Superblock,
    umount: *const fn() anyerror!void,

    pub const regfs = internal.regfs;
    pub const unregfs = internal.unregfs;
    pub const updfs = internal.updfs;
};

pub const FsInfo: type = struct {
    fs: *const Fs,
    flags: FsControlFlags,

    pub inline fn builder(fs: *const Fs, flags: FsControlFlags) @This() {
        return @This() {
            .fs = fs,
            .flags = flags,
        };
    }

    pub inline fn create(fs: *const Fs, flags: FsControlFlags) FsErr!*@This() {
        const ptr: *@This() = @ptrCast(allocator.sba.allocator.alloc(@This(), 1) catch return FsErr.FsAllocatorFailed);
        ptr.* = @This().builder(fs, flags);
        return ptr;
    }

    pub inline fn destroy(self: *@This()) FsErr!void {
        return allocator.sba.allocator.free(self)
            catch FsErr.FsAllocatorFailed;
    }
};

pub const FsControlFlags: type = packed struct {
    noumount: u1, // se recusa a desmontar
    nomount: u1, // se recusa a montar
    readonly: u1, // montagem apenas para leitura
    anon: u1, // searchFs nunca vai retornar
};

pub const FsKernelRegister: type = hashtable.hashMap([]const u8, *FsInfo, null, null);

pub const FsErr: type = error {
    MountFailed,
    UmountFailed,
    MountDenied,
    UmountDenied,
    FsAllocatorFailed,
    FsRegisterFailed,
    FsUnregisterFailed,
    NoNFound,
    FsCollision,
};
