// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: atomic.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("std").builtin;

pub fn atomicValue(comptime t: type) type {
    return struct {
        value: t,

        pub fn init(value: t) @This() {
            return @This() {
                .value = value,
            };
        }

        // builtin.AtomicOrder

        // unordered:
        // Ensures that the access observes a value that was actually stored,
        // but allows broad compiler reordering and should not be used
        // to build synchronization primitives.

        // monotonic:
        // Guarantees atomicity and places the operation in the coherent
        // modification order of this memory address. It can be used for counters,
        // states, and as part of synchronization algorithms.
        // It does not synchronize other variables.

        // acquire:
        // Ensures that operations below it happen after the acquisition.
        // When it observes a value published with release, it also makes
        // the changes performed before that release visible.

        // release:
        // Ensures that operations above it are published before the atomic operation.
        // It is commonly used when unlocking a mutex or announcing that data is ready.

        // acq_rel:
        // Combines acquire and release.
        // Publishes the operations above it and prevents the operations below it
        // from being moved before the atomic operation.
        // It is mainly used for atomic read-modify-write operations.

        // seq_cst:
        // This is the strongest memory ordering.
        // It provides acquire/release guarantees and also places all seq_cst
        // operations into a single global order observable by all threads.

        pub inline fn atomicLoad(self: *const @This(), comptime ordering: builtin.AtomicOrder) t {
            return @atomicLoad(t, &self.value, ordering);
        }

        pub inline fn atomicStore(self: *@This(), value: t, comptime ordering: builtin.AtomicOrder) void {
            @atomicStore(t, &self.value, value, ordering);
        }

        pub inline fn atomicRmw(self: *@This(), comptime op: builtin.AtomicRmwOp, operand: t, comptime ordering: builtin.AtomicOrder) t {
            return @atomicRmw(t, &self.value, op, operand, ordering);
        }

        /// cmpxchgStrong:
        /// Does not return a spurious failure. If the underlying machine operation
        /// fails spuriously, it may retry internally until the exchange succeeds or
        /// it confirms that the current value is actually different from the expected value.
        pub inline fn cmpxchgStrong(self: *@This(), expected_value: t, new_value: t, success_order: builtin.AtomicOrder, fail_order: builtin.AtomicOrder) ?t {
            return @cmpxchgStrong(t, &self.value, expected_value, new_value, success_order, fail_order);
        }

        /// cmpxchgWeak:
        /// May return a spurious failure even when the current value still matches
        /// the expected value. Therefore, it should be used inside loops that can
        /// retry the operation.
        pub inline fn cmpxchgWeak(self: *@This(), expected_value: t, new_value: t, success_order: builtin.AtomicOrder, fail_order: builtin.AtomicOrder) ?t {
            return @cmpxchgWeak(t, &self.value, expected_value, new_value, success_order, fail_order);
        }
    };
}
