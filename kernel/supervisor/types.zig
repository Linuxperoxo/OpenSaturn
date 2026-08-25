// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig      │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Supervisor: type = struct {
    pub const Status: type = enum(u1) {reserved, none};
    pub const Rewritten: type = enum(u2) {always, never, once};
    pub const Type: type = union(enum(u2)) {
        exception: []const u8,
        irq: void,
        syscall: void,
        none: void,
    };
    status: Status,
    rewritten: Rewritten,
    type: Type,
};

pub const SupervisorIsrTable: type = struct {
    pub const Isr: type = union(enum) {
        exception: ?*const fn([]const u8) void,
        noexception: ?*const fn() void,
    };
    status: Supervisor.Status,
    rewritten: Supervisor.Rewritten,
    type: Supervisor.Type,
    isr: Isr,
};

