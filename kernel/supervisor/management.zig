// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Supervisor: type = @import("types.zig").Supervisor;
const SupervisorIsrTable: type = @import("types.zig").SupervisorIsrTable;

const saturn_supervisor_table = @import("root").cpu.Interrupt.supervisor.__SaturnSupervisorTable__;

const fmt: type = struct {
    pub fn toString(comptime n: usize, comptime c: usize) [c]u8 {
        var num: usize = n;
        var str: [c]u8 = undefined;
        for(0..c) |i| {
            str[(c - 1) - i] = @intCast((num % 10) + '0');
            num = num / 10;
        }
        return str;
    }

    pub fn digitCount(comptime n: usize) usize {
        return comptime c: {
            if(n == 0) break :c 1;
            var num: usize = n;
            var count: usize = 0;
            while(num != 0) : (count += 1) {
                num = num / 10;
            }
            break :c count;
        };
    }
};

pub const supervisor_isr_table = sIT: {
    var arch_supervisor_isr_info: [saturn_supervisor_table.len]SupervisorIsrTable = undefined;
    for(0..saturn_supervisor_table.len) |i| {
        arch_supervisor_isr_info[i].rewritten = saturn_supervisor_table[i].rewritten;
        arch_supervisor_isr_info[i].status = saturn_supervisor_table[i].status;
        arch_supervisor_isr_info[i].type = saturn_supervisor_table[i].type;
        arch_supervisor_isr_info[i].isr = switch(saturn_supervisor_table[i].type) {
            .exception => .{ .exception = null },
            else => .{ .noexception = null },
        };
    }
    break :sIT arch_supervisor_isr_info;
};

pub const supervisor_handler_per_isr = sHP: {
    @setEvalBranchQuota(4096);
    var isr_handlers: [saturn_supervisor_table.len]*const fn() callconv(.c) void = undefined;
    var counts: struct {exception: usize, irq: usize, syscall: usize, none: usize} = .{
        .exception = 0,
        .irq = 0,
        .syscall = 0,
        .none = 0,
    };
    for(0..saturn_supervisor_table.len) |i| {
        isr_handlers[i] = iH: switch(saturn_supervisor_table[i].type) {
            .exception => {
                const exception = &(struct {
                    pub fn exception() callconv(.c) void {
                        @call(.never_inline, &exceptionHandler, .{i});
                    }
                }.exception);
                @export(exception, .{
                    .name = "exception" ++ "_" ++ fmt.toString(counts.exception, fmt.digitCount(counts.exception)),
                });
                counts.exception += 1;
                break :iH exception;
            },
            .irq => {
                const irq = &(struct {
                    pub fn irq() callconv(.c) void {
                        @call(.never_inline, &irqHandler, .{i});
                    }
                }.irq);
                @export(irq, .{
                    .name = "irq" ++ "_" ++ fmt.toString(counts.irq, fmt.digitCount(counts.irq)),
                });
                counts.irq += 1;
                break :iH irq;
            },
            .syscall => {
                const syscall = &(struct {
                    pub fn syscall() callconv(.c) void {
                        @call(.never_inline, &syscallHandler, .{i});
                    }
                }.syscall);
                @export(syscall, .{
                    .name = "syscall" ++ "_" ++ fmt.toString(counts.syscall, fmt.digitCount(counts.syscall)),
                });
                counts.syscall += 1;
                break :iH syscall;
            },
            .none => {
                const nonused = &(struct {
                    pub fn nonused() callconv(.c) void {
                        @call(.never_inline, &nonusedHandler, .{i});
                    }
                }.nonused);
                @export(nonused, .{
                    .name = "nonused" ++ "_" ++ fmt.toString(counts.none, fmt.digitCount(counts.none)),
                });
                counts.none += 1;
                break :iH nonused;
            },
        };
    }
    break :sHP isr_handlers;
};

fn exceptionHandler(_: usize) void {
    while(true) {}
}

fn syscallHandler(_: usize) void {
    while(true) {}
}

fn irqHandler(_: usize) void {
    while(true) {}
}

fn nonusedHandler(_: usize) void {
    while(true) {}
}
