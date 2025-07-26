// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig      │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const supervisor_T: type = struct {
    pub const status_T: type = enum(u1) {reserved, none};
    pub const rewritten_T: type = enum(u2) {always, never, once};
    pub const type_T: type = union(enum(u2)) {
        exception: []const u8,
        irq: void,
        syscall: void,
        none: void,
    };
    status: status_T,
    rewritten: rewritten_T,
    type: type_T,
};

pub const supervisorIsrTable_T: type = struct {
    pub const isr_T: type = union(enum) {
        exception: ?*const fn([]const u8) void,
        noexception: ?*const fn() void,
    };
    status: supervisor_T.status_T,
    rewritten: supervisor_T.rewritten_T,
    type: supervisor_T.type_T,
    isr: isr_T,
};

