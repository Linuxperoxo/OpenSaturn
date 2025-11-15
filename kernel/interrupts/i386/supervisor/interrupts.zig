// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interrupts.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

// Saturn Supervisor
const supervisor_T: type = @import("root").supervisor.supervisor_T;

// Internal
const idtEntry_t: type = @import("idt.zig").idtEntry_T;
const lidt_T: type = @import("idt.zig").lidt_T;

const InterruptGate: comptime_int = 0b1110;
const TrapGate: comptime_int = 0b1111;
const TaskGate: comptime_int = 0b0101;

// Exceptions Messagens
const exceptionsMessagens = @import("idt.zig").cpuExceptionsMessagens;

pub const __SaturnSupervisorTable__ = sst: {
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

var lidt: lidt_T = undefined;

pub fn init(handlers: [__SaturnSupervisorTable__.len]*const fn() callconv(.c) void) void {
    const idtEntries = comptime iE: {
        var entries: [__SaturnSupervisorTable__.len]idtEntry_t = undefined;
        for(0..__SaturnSupervisorTable__.len) |i| {
            entries[i].segment = 0x08;
            entries[i].flags = 0x80 | @as(u8, @intCast(InterruptGate));
            entries[i].always0 = 0x00;
        }
        break :iE entries;
    };
    { // Runtime block
        // Isso pode ser feito aqui pois estamos no baremetal, em um programa com OS, isso daria
        // um segfault, já que idtEntries é conhecido em tempo de compilação e montado inteiramente
        // na .rodata, pegar o endereço dele dessa maneira iria ser para um endereço de rodata
        lidt.entries = @constCast(&idtEntries);
        lidt.limit = (@sizeOf((idtEntry_t)) * __SaturnSupervisorTable__.len) - 1;
        // Aqui precisamos resolver o endereço das funções em execução, já que o compilador
        // sabe da existencia de uma função pois o assembly vamos ter uma label para aquela
        // função, mas mesmo assim o endereço ainda é um misterio para o compilador, ja que
        // fica por conta do linker em resolver os endereços
        for(0..__SaturnSupervisorTable__.len) |i| {
            lidt.entries[i].low = @intCast(@intFromPtr(handlers[i]) & 0xFFFF);
            lidt.entries[i].high = @intCast((@intFromPtr(handlers[i]) >> 16) & 0xFFFF);
        }
        asm volatile(
            \\ lidt (%eax)
            :
            :[_] "{eax}" (&lidt),
            : .{
                .eax = true,
            }
        );
    }
}
