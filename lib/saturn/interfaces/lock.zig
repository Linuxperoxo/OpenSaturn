// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: lock.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const LockErr_T: type = error {
    Deadlock,
    NoOwner,
    NotOwner
};

pub const VTable_T: type = struct {
    lock: *const fn(*anyopaque) LockErr_T!void,
    unlock: *const fn(*anyopaque) LockErr_T!void,
    tryLock: *const fn(*anyopaque) LockErr_T!bool,
};

pub const Lock_T: type = struct {
    private: *anyopaque,
    vtable: *const VTable_T,

    pub inline fn lock(self: *const @This()) LockErr_T!void {
        try self.vtable.lock(self.private);
    }

    pub inline fn unlock(self: *const @This()) LockErr_T!void {
        try self.vtable.unlock(self.private);
    }

    pub inline fn tryLock(self: *const @This()) LockErr_T!bool {
        return self.vtable.tryLock(self.private);
    }
};
