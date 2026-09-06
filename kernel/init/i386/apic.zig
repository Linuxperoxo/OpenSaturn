// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: apic.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const lapic: type = @import("lapic.zig");
pub const iopic: type = @import("ioapic.zig");

pub fn apicConfig() void {
    @call(.always_inline, &lapic.enableLAPIC, .{});

    // Usamos primeiro o assert para entrar no reset junto do LevelTriggered. Depois usamos o Deassert para
    // o core sair do reset e ficar pronto para receber um SIPI

    // Imagine sendo um botão, quando apertamos(assert), o processador entra em reset. Quando você
    // solta, o processador sai do reset, como eles são cores secundários, eles não executar o código de cara
    // como o BSP que executa a BIOS logo de cara, ele apenas fica esperando um SIPI. O Level só é relevante no comando
    // .Init, todos os outros não usa esse bit. Segundo a intel usar o TriggerMode como Edge, o bit Level é completamente
    // ignorado, e o comando simplesmente não vai funcionar
    @call(.always_inline, &lapic.sendIPI, .{
        lapic.ICRLow {
            .idt_entry = 0,
            .delivery_mode = .init,
            .dest_mode = .physical,
            .level = .assert,
            .trigger_mode = .level_triggered,
            .destination_shorthand = .all_except_current,
        },

        lapic.ICRHigh {
            .lapic_id = 1,
        }
    });

    @call(.always_inline, &lapic.sendIPI, .{
        lapic.ICRLow {
            .idt_entry = 0,
            .delivery_mode = .init,
            .dest_mode = .physical,
            .level = .deassert,
            .trigger_mode = .level_triggered,
            .destination_shorthand = .all_except_current,
        },

        lapic.ICRHigh {
        .lapic_id = 1,
        }
    });
}
