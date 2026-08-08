// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: atomic.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("std").builtin;

pub fn AtomicValue(comptime T: type) type {
    return struct {
        value: T,

        pub fn init(value: T) @This() {
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

        pub inline fn atomicLoad(self: *const @This(), comptime ordering: builtin.AtomicOrder) T {
            return @atomicLoad(T, &self.value, ordering);
        }

        pub inline fn atomicStore(self: *@This(), value: T, comptime ordering: builtin.AtomicOrder) void {
            @atomicStore(T, &self.value, value, ordering);
        }

        pub inline fn atomicRmw(self: *@This(), comptime op: builtin.AtomicRmwOp, operand: T, comptime ordering: builtin.AtomicOrder) T {
            return @atomicRmw(T, &self.value, op, operand, ordering);
        }

        /// cmpxchgStrong:
        /// Does not return a spurious failure. If the underlying machine operation
        /// fails spuriously, it may retry internally until the exchange succeeds or
        /// it confirms that the current value is actually different from the expected value.
        pub inline fn cmpxchgStrong(self: *@This(), expected_value: T, new_value: T, success_order: builtin.AtomicOrder, fail_order: builtin.AtomicOrder) ?T {
            return @cmpxchgStrong(T, &self.value, expected_value, new_value, success_order, fail_order);
        }

        /// cmpxchgWeak:
        /// May return a spurious failure even when the current value still matches
        /// the expected value. Therefore, it should be used inside loops that can
        /// retry the operation.
        pub inline fn cmpxchgWeak(self: *@This(), expected_value: T, new_value: T, success_order: builtin.AtomicOrder, fail_order: builtin.AtomicOrder) ?T {
            return @cmpxchgWeak(T, &self.value, expected_value, new_value, success_order, fail_order);
        }
    };
}
