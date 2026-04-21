// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig     │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const vfs: type = @import("root").core.vfs;
const hashtable: type = @import("root").lib.utils.hashtable;
const internal: type = @import("internal.zig");
const allocator: type = @import("allocator.zig");

pub const Fs_T: type = struct {
    name: []const u8,
    mount: *const fn() anyerror!*const vfs.Superblock_T,
    umount: *const fn() anyerror!void,

    pub const regfs = internal.regfs;
    pub const unregfs = internal.unregfs;
    pub const updfs = internal.updfs;
};

pub const FsInfo_T: type = struct {
    fs: *const Fs_T,
    flags: FsControlFlags_T,

    pub inline fn builder(fs: *const Fs_T, flags: FsControlFlags_T) @This() {
        return @This() {
            .fs = fs,
            .flags = flags,
        };
    }

    pub inline fn alloc(fs: *const Fs_T, flags: FsControlFlags_T) FsErr_T!*@This() {
        const ptr: *@This() = @ptrCast(allocator.sba.allocator.alloc(@This(), 1) catch return FsErr_T.FsAllocatorFailed);
        ptr.* = @This().builder(fs, flags);
        return ptr;
    }
};

pub const FsControlFlags_T: type = packed struct {
    noumount: u1, // se recusa a desmontar
    nomount: u1, // se recusa a montar
    readonly: u1, // montagem apenas para leitura
    anon: u1, // search_fs nunca vai retornar
};

pub const FsKernelRegister_T: type = hashtable.buildHashTable([]const u8, *FsInfo_T, null, null);

pub const FsErr_T: type = error {
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
