// ┌────────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interrupts.zig     │
// │            Author: Linuxperoxo                     │
// └────────────────────────────────────────────────────┘

const arch: type = @import("root").arch;
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
        .flags = 0x00 | @as(u8, @intCast(interrupt_gate)),
        .always0 = 0,
        .high = 0,
        .low = 0,
    },
} ** 256;

pub const idt_struct = [_]u8 {
    0,
} ** @sizeOf(IDTStruct_T);

pub fn idt_init() linksection(section_text_loader) callconv(.c) void {
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
}

