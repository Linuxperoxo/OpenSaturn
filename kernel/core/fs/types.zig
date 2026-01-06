// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig     │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const vfs: type = @import("root").core.vfs;
const c: type = @import("root").lib.utils.c;
const list: type = @import("root").lib.utils.list;

pub const Fs_T: type = struct {
    name: []const u8,
    mount: *const fn() anyerror!*const vfs.Superblock_T,
    umount: *const fn() anyerror!void,
    flags: packed struct {
        control: packed struct {
            noumount: u1, // se recusa a desmontar
            nomount: u1, // se recusa a montar
            readonly: u1, // montagem apenas para leitura
            anon: u1, // search_fs nunca vai retornar
        },
        internal: packed struct {
            mounted: u1 = 0, // fs mountado?
            registered: u1 = 0, // fs registrado?
            // tentativa de registrar o mesmo fs, seja por nome, ou por ponteiro
            collision: packed struct {
                name: u1 = 0,
                pointer: u1 = 0,

                pub inline fn some(self: *@This()) bool {
                    return c.c_bool(
                        @as(usize, @intCast(
                            (@as(u2, @intCast(self.name)) << 1) |
                            (self.pointer)
                        ))
                    );
                }
            } = .{},
            // operacoes negadas ao fs, caso readonly = 1 e alguem tente escrever no fs o write
            // passa a ser 1, mesma coisa para todos os outros
            fault: packed struct {
                mount: u1 = 0,
                umount: u1 = 0,
                write: u1 = 0,

                pub inline fn some(self: *@This()) bool {
                    return c.c_bool(
                        @as(usize, @intCast(
                            (@as(u3, @intCast(self.mount)) << 2) |
                            (@as(u2, @intCast(self.umount)) << 1) |
                            (self.write)
                        ))
                    );
                }
            } = .{},
        } = .{},
    },
};

pub const Collision_T: type = enum(u2) {
    name = 0b01,
    pointer = 0b10,
};

pub const FsRegister_T: type = struct {
    fs: list.BuildList(*Fs_T),
    flags: packed struct(u8) {
        init: u1,
        reserved: u7 = 0,
    },
};

pub const FsErr_T: type = error {
    MountFailed,
    UmountFailed,
    MountDenied,
    UmountDenied,
    WriteDenied,
    FsRegisterFailed,
    NoNFound,
    FsCollision,
    InitFailed,
};
