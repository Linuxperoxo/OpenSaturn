// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interrupts.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const supervisor_T: type = @import("root").supervisor.supervisor_T;

pub const __saturn_supervisor_table__ = sst: {
    var interrupts: [256]supervisor_T = undefined;
    var index: usize = 0;
    sw: switch(index) {
        0...31 => {
            interrupts[index].status = .reserved;
            interrupts[index].type = .exception;
            interrupts[index].rewritten = .never;
            index += 1;
            continue :sw index;
        },
        32...47 => {
            interrupts[index].status = .none;
            interrupts[index].type = .irq;
            interrupts[index].rewritten = .once;
            index += 1;
            continue :sw index;
        },
        48...255 => {
            interrupts[index].status = .none;
            interrupts[index].type = .none;
            interrupts[index].rewritten = .always;
            index += 1;
            continue :sw index;
        },
        else => {},
    }
    interrupts[0x80].rewritten = .once;
    interrupts[0x80].status = .none;
    interrupts[0x80].type = .syscall;

    break :sst interrupts;
};

pub fn init(handlers: [__saturn_supervisor_table__.len]?*const fn() void) void {
    _ = handlers;
}
