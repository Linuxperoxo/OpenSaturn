// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const supervisor_T: type = @import("types.zig").supervisor_T;
const supervisorIsrTable_T: type = @import("types.zig").supervisorIsrTable_T;

const SaturnSupervisorTable = @import("root").cpu.Interrupt.supervisor.__SaturnSupervisorTable__;

const fmt: type = struct {
    pub fn toString(comptime N: usize, comptime C: usize) [C]u8 {
        var num: usize = N;
        var str: [C]u8 = undefined;
        for(0..C) |i| {
            str[(C - 1) - i] = @intCast((num % 10) + '0');
            num = num / 10;
        }
        return str;
    }

    pub fn digitCount(comptime N: usize) usize {
        return comptime c: {
            if(N == 0) break :c 1;
            var num: usize = N;
            var count: usize = 0;
            while(num != 0) : (count += 1) {
                num = num / 10;
            }
            break :c count;
        };
    }
};

pub const supervisorIsrTable = sIT: {
    var archSupervisorISRInfo: [SaturnSupervisorTable.len]supervisorIsrTable_T = undefined;
    for(0..SaturnSupervisorTable.len) |i| {
        archSupervisorISRInfo[i].rewritten = SaturnSupervisorTable[i].rewritten;
        archSupervisorISRInfo[i].status = SaturnSupervisorTable[i].status;
        archSupervisorISRInfo[i].type = SaturnSupervisorTable[i].type;
        archSupervisorISRInfo[i].isr = switch(SaturnSupervisorTable[i].type) {
            .exception => .{ .exception = null },
            else => .{ .noexception = null },
        };
    }
    break :sIT archSupervisorISRInfo;
};

pub const supervisorHandlerPerIsr = sHP: {
    @setEvalBranchQuota(4096);
    var isrHandlers: [SaturnSupervisorTable.len]*const fn() callconv(.c) void = undefined;
    var counts: struct {exception: usize, irq: usize, syscall: usize, none: usize} = .{
        .exception = 0,
        .irq = 0,
        .syscall = 0,
        .none = 0,
    };
    for(0..SaturnSupervisorTable.len) |i| {
        isrHandlers[i] = iH: switch(SaturnSupervisorTable[i].type) {
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
    break :sHP isrHandlers;
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
