// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ioapic.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const ioapic_base_phys: u32 = 0xFEC00000;

pub const IOAPICRegs: type = enum(u8) {
    id_register = 0x00, // Contêm o ID do IOAPIC em bits 24-27, o resto é reservado(pode ser alterado, mas normalmente fixo)
    version_register = 0x01, // Contêm a versão 0-7 Bits e 16-23 a quantidade máxima de entrada Redirection Table, o resto é reservado. Apenas leitura
    arbitration_register = 0x02, // pega a arbitragem de prioridade nos bits 24-27. Todos os outros são reservador. Apenas leitura
    redirection_entry_register = 0x10, // Cada IRQ configurável ocupa dois registros: parte baixa e alta, exemplo: 0x12 e 0x13, vai de 0x10 a 0x3F
};

pub const IOAPICOffset: type = enum(u8) {
    reg_sel = 0x00, // Seleciona qual registrador acessar
    win = 0x10, // Leitura/escrita do registrador selecionado
};

// Bits 0–7: Interrupt Vector
// - Define qual vetor de interrupção será entregue ao processador.
// - Valor típico: 0x10 a 0xFE (0x00–0x1F são reservados para exceções da CPU).

// Bits 8–10: Delivery Mode
// - Define o tipo de entrega da interrupção.
//   000 = Fixed (normal),
//   001 = Lowest Priority,
//   010 = SMI (System Management Interrupt),
//   100 = NMI (Non-maskable interrupt),
//   101 = INIT,
//   111 = ExtINT (compatível com 8259 PIC).

// Bit 11: Destination Mode
// - Define como os bits 56–63 (Destination Field) são interpretados:
//   0 = Modo físico (bits 56–59 = APIC ID),
//   1 = Modo lógico (bits 56–63 = mapa lógico de CPUs).

// Bit 12: Delivery Status (somente leitura)
// - Indica se a interrupção está pendente de envio.
//   0 = Pronta/enviada, 1 = APIC ainda está enviando.

// Bit 13: Interrupt Input Pin Polarity
// - Define a polaridade do sinal de interrupção:
//   0 = Ativo em nível alto,
//   1 = Ativo em nível baixo.

// Bit 14: Remote IRR (somente leitura)
// - Usado apenas em modo level-triggered.
//   1 = LAPIC recebeu a interrupção e está aguardando EOI,
//   0 = EOI foi enviado, pronto para próxima interrupção.

// Bit 15: Trigger Mode
// - Tipo de ativação:
//   0 = Edge-triggered (borda),
//   1 = Level-triggered (nível).

// Bit 16: Interrupt Mask
// - 1 = Interrupção mascarada (desativada),
//   0 = Interrupção habilitada.

// Bits 17–55: Reservados
// - Não utilizados. Devem ser mantidos como zero.

// Bits 56–63: Destination Field
// - Se Destination Mode = 0 (físico): bits 56–59 = ID do APIC de destino.
// - Se Destination Mode = 1 (lógico): bits 56–63 = bitmap indicando CPUs destino.

pub const LowEntryRegisterLayout: type = packed struct {
    idt_entry: u8, // Número do vetor na IDT, aceita apenas de 0x10 a 0xFE, os primeeiros vetores são reservador para exceções da CPU
    delivery_mode: u3, // Modo de entrega (Fixed, NMI, etc.)
    dest_mode: u1, // Modo de endereçamento (físico = 0, lógico = 1)
    delivery_status: u1, // Leitura: 1 se pendente (não deve ser escrito)
    polarity: u1, // 0 = ativo alto, 1 = ativo baixo
    remote_irr: u1, // Leitura: 1 se IRQ ainda não foi reconhecida (APIC), ignorar na escrita
    trigger_mode: u1, // 0 = edge, 1 = level
    mask: u1, // 1 = mascarado (não entrega interrupção)
    reserved: u15 = 0,
};

pub const HighEntryRegisterLayout: type = packed struct {
    reserved: u24 = 0,
    lapic_id: u8, // ID do LAPIC de destino
};

pub fn writeIOAPIC(register: IOAPICRegs, data: u32) void {
    asm volatile(
        \\ movl %[SelectedRegister], %eax
        \\ movl %eax, %[IOAPICRegSel](%[IOAPICBase])
        \\ movl %[Data], %eax
        \\ movl %eax, %[IOAPICWin](%[IOAPICBase])

        :
        :[Data] "m" (&data),
         [SelectedRegister] "m" (&register),
         [IOAPICBase] "i" (ioapic_base_phys),
         [IOAPICRegSel] "i" (IOAPICOffset.reg_sel),
         [IOAPICWin] "i" (IOAPICOffset.win)
        : .{}
    );
}

pub fn readIOAPIC(register: IOAPICRegs) u32 {
    return asm volatile(
        \\ movl %[SelectedRegister], %eax
        \\ movl %eax, %[IOAPICRegSel](%[IOAPICBase])
        \\ movl %[IOAPICWin](%[IOAPICBase]), %eax

        :[_] "={eax}" (-> u32)
        :[SelectedRegister] "m" (&register),
         [IOAPICBase] "i" (ioapic_base_phys),
         [IOAPICRegSel] "i" (IOAPICOffset.reg_sel),
         [IOAPICWin] "i" (IOAPICOffset.win)
        : .{}
    );
}

pub fn maxIRQ() u8 {
    return ((@call(
        .always_inline,
        &readIOAPIC,
        .{
            IOAPICRegs.version_register
        }
    ) >> 16) & 0xFF); // Resultado disso é pegar os bits 0x00FF0000, isso é a quantidade de IRQ suportada pelo IOAPIC
}

pub fn setIRQ(idt_entry: u8, irq: u8, lapic_id: u8) void {
    @call(
        .always_inline, 
        &writeIOAPIC,
        .{
            .redirection_entry_register + irq * 2,
            LowEntryRegisterLayout {
                // TODO:
                .idt_entry = idt_entry,
            }
        }
    );

    @call(
        .always_inline, 
        &writeIOAPIC,
        .{
            .redirection_entry_register + irq * 2 + 1,
            HighEntryRegisterLayout {
                .lapic_id = lapic_id,
            }
        }
    );
}
