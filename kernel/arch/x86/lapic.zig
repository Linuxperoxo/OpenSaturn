// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: lapic.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const msr: type = @import("root").cpu.msr;

const LAPIC_BASE_PHYS: u32 = 0xFEE00000;
const LAPIC_ENABLE_BIT: u16 = 1 << 11;
const LAPIC_SVR_ENABLE: u16 = 1 << 8;

// MSRs (Model-Specific Registers) são registradores específicos do modelo de processador que permitem acesso a funcionalidades 
// avançadas e configurações do hardware. Eles são usados para controlar o comportamento do processador, como desempenho, 
// gerenciamento de energia e segurança. Para habilitar o LAPIC (Local Advanced Programmable Interrupt Controller), 
// é necessário configurar corretamente certos MSRs, pois eles controlam aspectos como a ativação do LAPIC e 
// a configuração de interrupções no sistema. O acesso aos MSRs é feito por instruções especiais, como RDMSR e WRMSR, 
// e geralmente requer privilégios de anel 0 (modo de kernel).
const IA32_APIC_BASE_MSR: u8 = 0x1B;

const LAPICOffsets: type = enum(u16) {
    IDRegister = 0x20,
    VersionRegister = 0x30,
    TaskPriorityRegister = 0x80,
    ArbitrationPriorityRegister = 0x90,
    ProcessorPriorityRegister = 0xA0,
    EndOfIntRegister = 0xB0,
    RemoteReadRegister = 0xC0,
    LogicalDestinationRegister = 0xD0,
    DestinationFormatRegister = 0xE0,
    SpuriousIntVectorRegister = 0xF0,
    InServiceRegisterLow = 0x100,
    InServiceRegisterHigh = 0x170,
    TriggerModeRegisterLow = 0x180,
    TriggerModeRegisterHigh = 0x1F0,
    InterruptRequestRegisterLow = 0x200,
    InterruptRequestRegisterHigh = 0x270,
    ErrorStatusRegister = 0x280,
    InterruptCommandRegisterLow = 0x300,
    InterruptCommandRegisterHigh = 0x310,
    LVTTimerRegister = 0x320,
    LVTThermalSensorRegister = 0x330,
    LVTPerformanceMonitoringCountersRegister = 0x340,
    LVTLINT0Register = 0x350,
    LVTLINT1Register = 0x360,
    LVTErrorRegister = 0x370,
    TimerInitialCountRegister = 0x380,
    TimerCurrentCountRegister = 0x390,
    TimerDivideConfigurationRegister = 0x3E0,
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
    Fixed = 0b000,
    Lowest = 0b001,
    SystemManagementInterrupt = 0b010,
    NonMaskableInterrupt = 0b011,
    Init = 0b101,
    Startup = 0b110,
    ExtINT = 0b111,
};

// Bit 11: Destination Mode
// - Define como os bits 56–63 (Destination Field) são interpretados:
//   0 = Modo físico (bits 56–59 correspondem ao APIC ID),
//   1 = Modo lógico (bits 56–63 representam um mapa lógico de CPUs).

pub const DestinationModes: type = enum(u1) {
    Physical,
    Logical,
};

// Bit 12: Delivery Status (somente leitura)
// - Indica o status da entrega da interrupção:
//   0 = Idle (interrupção já entregue),
//   1 = Pendente (a interrupção ainda está sendo entregue).

pub const DeliveryStatus: type = enum(u1) {
    Idle,
    Pending,
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
    Deassert,
    Assert,
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
    EdgeTriggered,
    LevelTriggered,
};

// Bits 18–19: Destination Shorthand
// - Define atalhos para o destino da interrupção:
//   00 = Nenhum (usar ICR_HIGH para definir o destino),
//   01 = Somente a CPU atual,
//   10 = Todos os LAPICs (broadcast),
//   11 = Todos os LAPICs, exceto a CPU que enviou.

pub const DestinationShorthands: type = enum(u2) {
    ICRHigh,
    CurrentCPU,
    AllLAPICs,
    ALLExceptCurrent,
};

pub const ICRLow: type = packed struct {
    IDTEntry: u8,
    DeliveryMode: DeliveryModes,
    DestMode: DestinationModes,
    DeliveryStatus: DeliveryStatus = .Idle,
    Reserved0: u1 = 0,
    Level: Levels,
    TriggerMode: TriggerModes,
    Reserved1: u2 = 0,
    DestinationShorthand: DestinationShorthands,
    Reserved2: u12 = 0,
};

pub const ICRHigh: type = packed struct {
    Reserved: u24 = 0,
    LAPICid: u8, // ID do LAPIC de destino
};

pub fn enableLAPIC() void {
    var msrReturn: msr.MsrReturn = @call(
        .always_inline,
        &msr.rdmsr,
        .{
            IA32_APIC_BASE_MSR,
        }
    );
   
    msrReturn.Low |= 0x800; // Bit que ativa o APIC

    @call(
        .always_inline,
        msr.wrmsr,
        .{
            IA32_APIC_BASE_MSR,
            msrReturn.Low,
            msrReturn.High
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
        :[I0] "i" (comptime LAPIC_BASE_PHYS + @intFromEnum(LAPICOffsets.SpuriousIntVectorRegister)),
        :"eax"
    );
}

pub fn sendIPI(ICRL: ICRLow, ICRH: ICRHigh) void {
    asm volatile(
        \\ movl %[I1], %ebx
        \\ movl %edx,  (%ebx)
        \\ movl %[I0], %ebx
        \\ movl %eax,  (%ebx)

        :
        :[_] "{eax}" (ICRL),
         [_] "{edx}" (ICRH),
         [I0] "i" (comptime LAPIC_BASE_PHYS + @intFromEnum(LAPICOffsets.InterruptCommandRegisterLow)),
         [I1] "i" (comptime LAPIC_BASE_PHYS + @intFromEnum(LAPICOffsets.InterruptCommandRegisterHigh))
        :
    );
}
