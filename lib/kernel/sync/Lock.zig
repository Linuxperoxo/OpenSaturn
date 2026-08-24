// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: Lock.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const LockErr: type = error {
    Deadlock,
    NoOwner,
    NotOwner
};

pub const VTable: type = struct {
    lock: *const fn(*anyopaque) LockErr!void,
    unlock: *const fn(*anyopaque) LockErr!void,
    tryLock: *const fn(*anyopaque) LockErr!bool,
};

private: *anyopaque,
vtable: *const VTable,

pub inline fn lock(self: *const @This()) LockErr!void {
    try self.vtable.lock(self.private);
}

pub inline fn unlock(self: *const @This()) LockErr!void {
    try self.vtable.unlock(self.private);
}

pub inline fn tryLock(self: *const @This()) LockErr!bool {
    return self.vtable.tryLock(self.private);
}
