// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig     │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const vfs: type = @import("root").core.vfs;
const c: type = @import("root").kernel.utils.c;
const list: type = @import("root").kernel.utils.list;

pub const Fs_T: type = struct {
    name: []const u8,
    mount: *const fn() FsErr_T!*const vfs.Superblock_T,
    umount: *const fn() FsErr_T!void,
    flags: packed struct {
        control: packed struct {
            noumount: u1, // se recusa a desmontar
            nomount: u1, // se recusa a montar
            readonly: u1, // montagem apenas para leitura
            anon: u1, // search_fs nunca vai retornar
        },
        internal: packed struct(u8) {
            mounted: u1, // fs mountado?
            registered: u1, // fs registrado?
            // tentativa de registrar o mesmo fs, seja por nome, ou por ponteiro
            collision: packed struct(u2) {
                name: u1,
                pointer: u1,

                pub inline fn some(self: *@This()) bool {
                    return c.c_bool(
                        @as(usize, @intCast(
                            (@as(u2, @intCast(self.name)) << 1) |
                            (self.pointer)
                        ))
                    );
                }
            },
            // operacoes negadas ao fs, caso readonly = 1 e alguem tente escrever no fs o write
            // passa a ser 1, mesma coisa para todos os outros
            fault: packed struct(u3) {
                mount: u1,
                umount: u1,
                write: u1,

                pub inline fn some(self: *@This()) bool {
                    return c.c_bool(
                        @as(usize, @intCast(
                            (@as(u3, @intCast(self.mount)) << 2) |
                            (@as(u2, @intCast(self.umount)) << 1) |
                            (self.write)
                        ))
                    );
                }
            },
            reserved: u1 = 0,
        },
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
};
