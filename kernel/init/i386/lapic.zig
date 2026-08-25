// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: lapic.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const msr: type = @import("msr.zig");

const lapic_base_phys: u32 = 0xFEE00000;
const lapic_enable_bit: u16 = 1 << 11;
const lapic_svr_enable: u16 = 1 << 8;

// MSRs (Model-Specific Registers) são registradores específicos do modelo de processador que permitem acesso a funcionalidades 
// avançadas e configurações do hardware. Eles são usados para controlar o comportamento do processador, como desempenho, 
// gerenciamento de energia e segurança. Para habilitar o LAPIC (Local Advanced Programmable Interrupt Controller), 
// é necessário configurar corretamente certos MSRs, pois eles controlam aspectos como a ativação do LAPIC e 
// a configuração de interrupções no sistema. O acesso aos MSRs é feito por instruções especiais, como RDMSR e WRMSR, 
// e geralmente requer privilégios de anel 0 (modo de kernel).
const ia32_apic_base_msr: u8 = 0x1B;

const LAPICOffsets: type = enum(u16) {
    id_register = 0x20,
    version_register = 0x30,
    task_priority_register = 0x80,
    arbitration_priority_register = 0x90,
    processor_priority_register = 0xA0,
    end_of_int_register = 0xB0,
    remote_read_register = 0xC0,
    logical_destination_register = 0xD0,
    destination_format_register = 0xE0,
    spurious_int_vector_register = 0xF0,
    in_service_register_low = 0x100,
    in_service_register_high = 0x170,
    trigger_mode_register_low = 0x180,
    trigger_mode_register_high = 0x1F0,
    interrupt_request_register_low = 0x200,
    interrupt_request_register_high = 0x270,
    error_status_register = 0x280,
    interrupt_command_register_low = 0x300,
    interrupt_command_register_high = 0x310,
    lvt_timer_register = 0x320,
    lvt_thermal_sensor_register = 0x330,
    lvt_performance_monitoring_counters_register = 0x340,
    lvt_lint0_register = 0x350,
    lvt_lint1_register = 0x360,
    lvt_error_register = 0x370,
    timer_initial_count_register = 0x380,
    timer_current_count_register = 0x390,
    timer_divide_configuration_register = 0x3E0,
};

// Bits 0–7: IDTEntry
// - Aqui dependendo do contexto pode funcionar de maneira diferente.
// - Se Delivery Mode = 0b000 (Fixed)
//   - Este valor representa um índice da IDT do core
// - Se Delivery Mode = 0b110 (Startup IPI)
//   - Este valor é tratado como um "Startup Vector", e será deslocado à esquerda por 12 bits,
//     formando um endereço físico onde o core começará a execução em modo real (real mode).
//   - Ou seja: endereço de execução = IDTEntry << 12 (deve estar abaixo de 1 MiB).
// - Portanto, esse campo representa "ou um vetor de interrupção (IDT)" ou "um endereço inicial",
//   dependendo do modo de entrega (Delivery Mode).

// Bits 8–10: Delivery Mode
// - Define o tipo de entrega da interrupção.
//   000 = Fixed (interrupção normal),
//   001 = Lowest Priority (prioridade mais baixa),
//   010 = SMI (System Management Interrupt),
//   011 = Reservado,
//   100 = NMI (Non-Maskable Interrupt),
//   101 = INIT (inicia um processador),
//   110 = Startup (SIPI, usado para iniciar um núcleo AP),
//   111 = ExtINT (para compatibilidade com o PIC 8259).

pub const DeliveryModes: type = enum(u3) {
    fixed = 0b000,
    lowest = 0b001,
    system_management_interrupt = 0b010,
    non_maskable_interrupt = 0b011,
    init = 0b101,
    startup = 0b110,
    ext_int = 0b111,
};

// Bit 11: Destination Mode
// - Define como os bits 56–63 (Destination Field) são interpretados:
//   0 = Modo físico (bits 56–59 correspondem ao APIC ID),
//   1 = Modo lógico (bits 56–63 representam um mapa lógico de CPUs).

pub const DestinationModes: type = enum(u1) {
    physical,
    logical,
};

// Bit 12: Delivery Status (somente leitura)
// - Indica o status da entrega da interrupção:
//   0 = Idle (interrupção já entregue),
//   1 = Pendente (a interrupção ainda está sendo entregue).

pub const DeliveryStatus: type = enum(u1) {
    idle,
    pending,
};

// Bit 14: Level (Assert/Deassert)
// - Define o estado do sinal de interrupção:
//
//   0 = Deassert (liberação do reset)
//   1 = Assert (acionamento do reset)
//
// O bit `Level` é usado especificamente para interrupções do tipo INIT (reset de processador).
// 
// Assert (Level = 1): Este valor sinaliza que o processador de destino deve ser colocado
// em um estado de reset. Em termos práticos, o processador "desliga" temporariamente,
// como um botão de reset sendo pressionado.
//
// Deassert (Level = 0): Quando o bit `Level` é deassertado, ou seja, quando ele é
// colocado em 0, o reset é liberado, permitindo que o processador de destino continue
// a execução, normalmente reiniciando sua sequência de boot.

pub const Levels: type = enum(u1) {
    deassert,
    assert,
};

// Bit 15: Trigger Mode
// - Define o tipo de disparo da interrupção, ou seja, como a interrupção será acionada:
//   - 0 = Edge-Triggered (Disparo por Borda):
//     - A interrupção é acionada apenas quando ocorre uma transição de borda no sinal de interrupção.
//     - Isso significa que a interrupção ocorre quando o sinal muda de baixo para alto (borda de subida) ou de alto para baixo (borda de descida).
//     - Este modo é útil para capturar eventos discretos ou momentâneos, como o pressionamento de um botão ou a mudança de estado de um sinal.
//     - Uma vez que a transição seja detectada, a interrupção é gerada apenas uma vez, e o sistema pode continuar a monitorar o sinal sem ser interrompido repetidamente até que outra transição ocorra.
//
//   - 1 = Level-Triggered (Disparo por Nível):
//     - A interrupção é acionada quando o sinal de interrupção está em um nível ativo, ou seja, nível alto ou nível baixo.
//     - A interrupção permanece ativa enquanto o sinal de interrupção estiver no nível especificado (alto ou baixo).
//     - Esse modo é útil para monitorar sinais contínuos ou falhas no sistema, onde a interrupção deve permanecer ativa até que o sinal seja removido ou alterado.
//     - Em Level-Triggered, a interrupção não é disparada apenas uma vez, mas sim enquanto o sinal de interrupção continuar no nível ativo.
//     - Esse modo pode ser útil para detectar falhas persistentes de hardware ou eventos de longa duração que necessitam de uma resposta contínua do sistema. 

pub const TriggerModes: type = enum(u1) {
    edge_triggered,
    level_triggered,
};

// Bits 18–19: Destination Shorthand
// - Define atalhos para o destino da interrupção:
//   00 = Nenhum (usar ICR_HIGH para definir o destino),
//   01 = Somente a CPU atual,
//   10 = Todos os LAPICs (broadcast),
//   11 = Todos os LAPICs, exceto a CPU que enviou.

pub const DestinationShorthands: type = enum(u2) {
    icr_high,
    current_cpu,
    all_lapics,
    all_except_current,
};

pub const ICRLow: type = packed struct {
    idt_entry: u8,
    delivery_mode: DeliveryModes,
    dest_mode: DestinationModes,
    delivery_status: DeliveryStatus = .idle,
    reserved0: u1 = 0,
    level: Levels,
    trigger_mode: TriggerModes,
    reserved1: u2 = 0,
    destination_shorthand: DestinationShorthands,
    reserved2: u12 = 0,
};

pub const ICRHigh: type = packed struct {
    reserved: u24 = 0,
    lapic_id: u8, // ID do LAPIC de destino
};

pub fn enableLAPIC() void {
    var msr_return: msr.MsrReturn = @call(
        .always_inline,
        &msr.rdmsr,
        .{
            ia32_apic_base_msr,
        }
    );
   
    msr_return.low |= 0x800; // Bit que ativa o APIC

    @call(
        .always_inline,
        msr.wrmsr,
        .{
            ia32_apic_base_msr,
            msr_return.low,
            msr_return.high
        }
    );

    asm volatile(
        \\ # Configurando o Spurious
        \\ # Bit 0-7: Entrada do IDT
        \\ # Bit 8: Se 1 o LAPIC é habilitado, se 0 desabilitado
        \\ # Bit 12: Se estiver definido as mensagens EOI não serão transmitidas
        \\ # Bit 12-15: Reservado
        \\
        \\ movl %[I0],  %edi
        \\ movl (%edi), %eax
        \\ bts  $8,     %eax
        \\ movl %eax,   (%edi)

        :
        :[I0] "i" (comptime lapic_base_phys + @intFromEnum(LAPICOffsets.spurious_int_vector_register)),
        : .{
            .eax = true,
        }
    );
}

pub fn sendIPI(icr_low: ICRLow, icr_high: ICRHigh) void {
    asm volatile(
        \\ movl %[I1], %ebx
        \\ movl %edx,  (%ebx)
        \\ movl %[I0], %ebx
        \\ movl %eax,  (%ebx)

        :
        :[_] "{eax}" (icr_low),
         [_] "{edx}" (icr_high),
         [I0] "i" (comptime lapic_base_phys + @intFromEnum(LAPICOffsets.interrupt_command_register_low)),
         [I1] "i" (comptime lapic_base_phys + @intFromEnum(LAPICOffsets.interrupt_command_register_high))
        : .{}
    );
}
