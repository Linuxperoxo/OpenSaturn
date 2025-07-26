// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interrupts.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

// Saturn Supervisor
const supervisor_T: type = @import("root").supervisor.supervisor_T;

// Internal
const idtEntry_t: type = @import("idt.zig").idtEntry_T;
const lidt_T: type = @import("idt.zig").lidt_T;

// Exceptions Messagens
pub const exceptionsMessagens = @import("idt.zig").cpuExceptionsMessagens;

pub const __saturn_supervisor_table__ = sst: {
    var interrupts: [256]supervisor_T = undefined;
    var index: usize = 0;
    sw: switch(index) {
        0...31 => {
            interrupts[index].status = .reserved;
            interrupts[index].type = .{ .exception = exceptionsMessagens[index] };
            interrupts[index].rewritten = .never;
            index += 1;
            continue :sw index;
        },
        32...47 => {
            interrupts[index].status = .none;
            interrupts[index].type = .{ .irq = undefined };
            interrupts[index].rewritten = .once;
            index += 1;
            continue :sw index;
        },
        48...255 => {
            interrupts[index].status = .none;
            interrupts[index].type = .{ .none = undefined };
            interrupts[index].rewritten = .always;
            index += 1;
            continue :sw index;
        },
        else => {},
    }
    interrupts[0x80].rewritten = .once;
    interrupts[0x80].status = .none;
    interrupts[0x80].type = .{ .syscall = undefined };

    break :sst interrupts;
};

pub fn init(handlers: [__saturn_supervisor_table__.len]*const fn() callconv(.c) void) void {
    _ = handlers;
}
