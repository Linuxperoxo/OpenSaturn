// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const vfs: type = @import("root").interfaces.vfs;

pub const Major: type = u5;
pub const Minor: type = u4;

pub const DevErr: type = error {
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

pub const Ops: type = enum {
    ioctl,
    mount,
    umount,
    open,
    close,
    read,
    write,
};

pub const DevType: type = enum {
    char,
    block,
};

pub const DevOps: type = struct {
    ioctl: ?*const fn(Minor, usize, ?*anyopaque) anyerror!usize = null,
    mount: ?*const fn(Minor) anyerror!*const vfs.Superblock = null,
    umount: ?*const fn(Minor) anyerror!void = null,
    open: ?*const fn(Minor) anyerror!void = null,
    close: ?*const fn(Minor) anyerror!void = null,
    read: ?*const fn(Minor, usize) anyerror![]u8 = null,
    write: ?*const fn(Minor, []const u8, usize) anyerror!void = null,
};

pub const Dev: type = struct {
    name: []const u8,
    ops: *const DevOps, // device op
    type: DevType,
    minor: ?*const fn(Minor) anyerror!void = null,
    flags: packed struct {
        control: packed struct {
            minor: u1, // aceita novos minors
            max: u4, // numero maximo de minors
        },
        internal: packed struct {
            total: u4 = 0, // numero de minors
        } = .{},
    },
};

pub const DevBranch: type = struct {
    dev: *const Dev,
    minors: [16]u1,

    pub fn validadeMinor(self: *@This(), minor: Minor) void {
        self.minors[minor] = 1;
    }

    pub fn invalidateMinor(self: *@This(), minor: Minor) void {
        // minor 0 e a primeira instancia do dev, sempre deve existir
        if(minor == 0)
            return;
        self.minors[minor] = 0;
    }

    pub fn isValidMinor(self: *const @This(), minor: Minor) bool {
        return self.minors[minor] == 1;
    }
};
