// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: cpu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const gdt: type = @import("gdt.zig");
pub const apic: type = @import("apic.zig");
pub const msr: type = @import("msr.zig");
//pub const pic: type = @import("pic.zig");

pub fn init() void {
    @call(.always_inline, gdt.GDT.load, gdt.GDT {
        .Entries = @constCast(&[_]gdt.GDTEntry {
            @call(.compile_time, gdt.GDT.newEntry, .{
                0x00,
                0x00,
                0x00,
                0x00,
            }),
            @call(.compile_time, gdt.GDT.newEntry, .{
                0x00,
                0xFFFF,
                0x0C,
                0x9A,
            }),
            @call(.compile_time, gdt.GDT.newEntry, .{
                0x00,
                0xFFFF,
                0x0C,
                0x92,
            }),
        }),
    });

    @call(.always_inline, &apic.lapic.enableLAPIC, .{});

    // Usamos primeiro o assert para entrar no reset junto do LevelTriggered. Depois usamos o Deassert para
    // o core sair do reset e ficar pronto para receber um SIPI

    // Imagine sendo um botão, quando apertamos(assert), o processador entra em reset. Quando você
    // solta, o processador sai do reset, como eles são cores secundários, eles não executar o código de cara
    // como o BSP que executa a BIOS logo de cara, ele apenas fica esperando um SIPI. O Level só é relevante no comando
    // .Init, todos os outros não usa esse bit. Segundo a intel usar o TriggerMode como Edge, o bit Level é completamente
    // ignorado, e o comando simplesmente não vai funcionar
    @call(.always_inline, &apic.lapic.sendIPI, .{
        apic.lapic.ICRLow {
            .IDTEntry = 0,
            .DeliveryMode = .Init,
            .DestMode = .Physical,
            .Level = .Assert,
            .TriggerMode = .LevelTriggered,
            .DestinationShorthand = .ALLExceptCurrent,
        },

        apic.lapic.ICRHigh {
            .LAPICid = 1,
        }
    });

    @call(.always_inline, &apic.lapic.sendIPI, .{
        apic.lapic.ICRLow {
            .IDTEntry = 0,
            .DeliveryMode = .Init,
            .DestMode = .Physical,
            .Level = .Deassert,
            .TriggerMode = .LevelTriggered,
            .DestinationShorthand = .ALLExceptCurrent,
        },

        apic.lapic.ICRHigh {
            .LAPICid = 1,
        }
    });
}
