// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const initSupervisor_T: type = fn([]*const fn() void) void;

pub const supervisor_T: type = struct {
    type: enum(u2) {exception, syscall, irq, none},
    status: enum(u1) {reserved, none},
    rewritten: enum(u2) {always, never, once},
};

pub const isr_T: type = struct {
    exception: []*const fn() void,
    irq: []*const fn() void,
    syscall: []*const fn() void,
};

