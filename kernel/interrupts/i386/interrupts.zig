// ┌────────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interrupts.zig     │
// │            Author: Linuxperoxo                     │
// └────────────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const events: type = @import("root").core.events;

pub const handler: type = @import("handler.zig");
pub const csi: type = @import("csi.zig");

const IDTEntry_T: type = @import("idt.zig").IDTEntry_T;
const IDTStruct_T: type = @import("idt.zig").IDTStruct_T;

const interrupt_gate: comptime_int = 0b1110;
const trap_gate: comptime_int = 0b1111;
const task_gate: comptime_int = 0b0101;

const section_text_loader = arch.sections.section_text_loader;
const section_data_loader = arch.sections.section_data_loader;
const section_data_persist = arch.sections.section_data_persist;

const exceptionsMessagens = @import("idt.zig").cpuExceptionsMessagens;

pub var idt_entries = [_]IDTEntry_T {
    IDTEntry_T {
        .segment = 0x08,
        .flags =  0x8E | 0x60,
        .always0 = 0,
        .high = 0,
        .low = 0,
    },
} ** 256;

pub var idt_struct = [_]u8 {
    0,
} ** @sizeOf(IDTStruct_T);

// idt_init is a phys address
pub fn idt_init() linksection(section_text_loader) callconv(.c) void {
    for(0..handler.csi_isr.len) |i| {
        idt_entries[i].high = @intCast(@intFromPtr(handler.csi_isr[i]) >> 16);
        idt_entries[i].low = @intCast(@intFromPtr(handler.csi_isr[i]) & 0xFFFF);
    }
    asm volatile(
        \\ movl $idt_entries, %eax
        \\ movl $idt_struct, %edi
        \\ movw %bx, (%edi)
        \\ movl %eax, 2(%edi)
        \\ lidt (%edi)
        :
        :[_] "{bx}" (idt_entries.len * @sizeOf(IDTEntry_T) - 1)
        : .{
            .eax = true,
            .edi = true,
        }
    );
    asm volatile(
        \\ int $0
    );
}
