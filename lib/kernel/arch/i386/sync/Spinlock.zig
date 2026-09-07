// ┌────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: Spinlock.zig   │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const sync: type = @import("sync.zig");
const atomic: type = @import("root").lib.kernel.sync.atomic;

const Spinlock: type = @This();
const AtomicState: type = atomic.AtomicValue(enum(u1) { free, blocked });

state: AtomicState,

pub inline fn init() @This() {
    return @This(){
        .state = AtomicState.init(.free),
    };
}

pub fn lock(self: *@This()) void {
    while (self.state.cmpxchgWeak(.free, .blocked, .acquire, .monotonic) != null) {
        while (self.state.atomicLoad(.monotonic) == .blocked) {
            sync.spinLoopHint();
        }
    }
}

pub fn tryLock(self: *@This()) bool {
    if (self.state.cmpxchgStrong(.free, .blocked, .acquire, .monotonic) != null)
        return false;
    return true;
}

pub fn unlock(self: *@This()) void {
    self.state.atomicStore(.free, .release);
}

pub fn isLocked(self: *@This()) bool {
    return self.state.atomicLoad(.monotonic) == .blocked;
}
