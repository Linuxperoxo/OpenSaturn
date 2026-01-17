// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").interfaces.vfs;
const builtin: type = @import("builtin");

pub const Major_T: type = u5;
pub const Minor_T: type = u4;

pub const DevErr_T: type = error {
    MajorNoNFound,
    MinorCollision,
    MinorNoExist,
    MainMinorOperation,
    WithoutMajor,
    MajorCollision,
    InvalidOperation,
    MinorDenied,
    MinorDoubleFree,
};

pub const Ops_T: type = enum {
    ioctl,
    mount,
    umount,
    open,
    close,
    read,
    write,
};

pub const DevType_T: type = enum {
    char,
    block,
};

pub const DevOps_T: type = struct {
    ioctl: ?*const fn(Minor_T, usize, ?*anyopaque) anyerror!usize = null,
    mount: if(!builtin.is_test) ?*const fn(Minor_T) anyerror!*const vfs.Superblock_T else void =  if(!builtin.is_test) null else {},
    umount: ?*const fn(Minor_T) anyerror!void = null,
    open: ?*const fn(Minor_T) anyerror!void = null,
    close: ?*const fn(Minor_T) anyerror!void = null,
    read: ?*const fn(Minor_T, usize) anyerror![]u8 = null,
    write: ?*const fn(Minor_T, []const u8, usize) anyerror!void = null,
};

pub const Dev_T: type = struct {
    name: []const u8,
    ops: *const DevOps_T, // device op
    type: DevType_T,
    minor: ?*const fn(Minor_T) anyerror!void = null,
    flags: packed struct {
        control: packed struct {
            minor: u1, // aceita novos minors
            max: u4, // numero maximo de minors
        },
        internal: packed struct {
            total: u4 = 0, // numero de minors
        },
    },
};

pub const DevBranch_T: type = struct {
    dev: *const Dev_T,
    minors: [16]u1,

    pub fn validade_minor(self: *@This(), minor: Minor_T) void {
        self.minors[minor] = 1;
    }

    pub fn invalidate_minor(self: *@This(), minor: Minor_T) void {
        // minor 0 e a primeira instancia do dev, sempre deve existir
        if(minor == 0)
            return;
        self.minors[minor] = 0;
    }

    pub fn is_valid_minor(self: *const @This(), minor: Minor_T) bool {
        return self.minors[minor] == 1;
    }
};
