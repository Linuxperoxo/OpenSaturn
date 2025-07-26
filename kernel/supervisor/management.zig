// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const supervisor_T: type = @import("types.zig").supervisor_T;
const supervisorIsrTable_T: type = @import("types.zig").supervisorIsrTable_T;

const arch__saturn_supervisor_table__ = @import("root").interrupts.__saturn_supervisor_table__;

pub const supervisorIsrTable = sIT: {
    var archSupervisorISRInfo: [arch__saturn_supervisor_table__.len]supervisorIsrTable_T = undefined;
    for(0..arch__saturn_supervisor_table__.len) |i| {
        archSupervisorISRInfo[i].rewritten = arch__saturn_supervisor_table__[i].rewritten;
        archSupervisorISRInfo[i].status = arch__saturn_supervisor_table__[i].status;
        archSupervisorISRInfo[i].type = arch__saturn_supervisor_table__[i].type;
        archSupervisorISRInfo[i].isr = switch(arch__saturn_supervisor_table__[i].type) {
            .exception => .{ .exception = null },
            else => .{ .noexception = null },
        };
    }
    break :sIT archSupervisorISRInfo;
};

pub const supervisorHandlerPerIsr = sHP: {
    var isrHandlers: [arch__saturn_supervisor_table__.len]?*const fn() void = undefined;
    for(0..arch__saturn_supervisor_table__.len) |i| {
        isrHandlers[i] = switch(arch__saturn_supervisor_table__[i].type) {
            .exception => &(struct { pub fn exception() void { @call(.never_inline, exception_handler, .{i}); } }.exception),
            .irq => &(struct { pub fn irq() void { @call(.never_inline, irq_handler, .{i}); } }.irq),
            .syscall => &(struct { pub fn syscall() void { @call(.never_inline, syscall_handler, .{i}); } }.syscall),
            .none => null,
        };
    }
    break :sHP isrHandlers;
};

fn exception_handler(_: usize) void {

}

fn syscall_handler(_: usize) void {

}

fn irq_handler(_: usize) void {

}
