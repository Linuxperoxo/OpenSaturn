// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const cpu: type = @import("saturn/cpu");
pub const core: type = @import("saturn/lib").core;
pub const interfaces: type = @import("saturn/lib").interfaces;
pub const io: type = @import("saturn/lib").io;

const gdt: type = cpu.gdt;
const apic: type = cpu.apic;

const GDT: cpu.gdt.GDT = cpu.gdt.GDT {
    .Entries = @constCast(&[_]gdt.GDTEntry {
        @call(
            .compile_time, 
            &gdt.GDT.newEntry,
            .{
                0x00,
                0x00,
                0x00,
                0x00,
            }
        ),

        @call(
            .compile_time, 
            &gdt.GDT.newEntry,
            .{
                0x00,
                0xFFFFF,
                0x0C,
                0x9A,
            }
        ),

        @call(
            .compile_time, 
            &gdt.GDT.newEntry,
            .{
                0x00,
                0xFFFFF,
                0x0C,
                0x92,
            }
        ),
    }),
};

// callconv(.naked) não tem prólogo e epílogo automáticos é simplesmente fazer uma função do 0,
// o compilador não adiciona o código de prólogo/epílogo para salvar/restaurar registradores ou
// manipular a pilha, como alocações e desalocação. 
//
// linksection(".text.saturn.entry") serve para por essa label em uma section explícita, poderiamos
// usar o @export para isso
//
// export serve para deixar o símbolo vísivel no assembly, ou seja, poderiamos usar o asm volatile(\\call Sentry);
// em qualquer arquivo, já que o símbolo está vísivel em todo o assembly.
export fn Sentry(
    AtlasVModeStruct: u32
) linksection(".text.entry") callconv(.Naked) noreturn { 
    _ = AtlasVModeStruct;
    // Este trecho de assembly habilita a FPU e o conjunto de instruções SSE:
    //
    // * Limpa o bit EM (bit 2) do CR0 para permitir instruções de ponto flutuante reais, quanto 1 o processador gera uma interrupção
    //   exception 7 - Device Not Available (NM), isso é bom para o kernel quer gerenciar o acesso à FPU por\ processo (e precisa salvar/restaurar o contexto)
    //   da FPU, ou seja, podemos apenas habilitar a FPU quando um processo gerar essa interrupção.
    //
    // * Seta o bit MP (bit 1):
    //      MP = Monitor Coprocessor. Esse bit controla se as instruções FPU (como WAIT/FWAIT)
    //      devem gerar uma exceção (#NM - Device Not Available) quando o bit TS (Task Switched) estiver setado.
    //
    //  Se MP = 1 e TS = 1:
    //      - Qualquer instrução FPU (inclusive WAIT/FWAIT) gera a exceção #NM.
    //      - Isso é usado para implementar "lazy FPU context switching":
    //          - O sistema operacional marca TS = 1 ao trocar de tarefa.
    //          - Se a nova tarefa tentar usar a FPU, a exceção #NM ocorre.
    //          - O handler salva o estado da FPU da tarefa anterior, restaura o da nova, e limpa TS.
    //          - Isso economiza tempo, evitando salvar/restaurar o contexto da FPU a cada troca de tarefa.
    //
    //  Se MP = 0:
    //      - Instruções WAIT/FWAIT não geram exceção mesmo se TS = 1.
    //      - Isso impede a detecção automática do uso da FPU.
    //
    // * Seta os bits OSFXSR (bit 9) do CR4 para habilitar salvamento de contexto e restauração do FPU FXSAVE/FXRSTOR,
    //   e OSXMMEXCPT (bit 10) do CR4 para habilitar SSE e exceções SSE.OTE:

    // NOTE: Configurar o SSE/FPU é importante aqui já que o compilador zig pode
    //  usar essas instruções mesmo em um ambiente bare-metal

    asm volatile(
        \\ cli
        \\ movl $0xF00000, %esp
        \\ movl %cr0,      %eax
        \\ andl $0xFFFB,   %eax
        \\ orl  $0x02,     %eax
        \\ movl %eax,      %cr0
        \\ movl %cr4,      %eax
        \\ orl  $1 << 9,   %eax
        \\ orl  $1 << 10,  %eax
        \\ movl %eax,      %cr4
        \\ call Sinit
        \\ call Smain

        :
        :
        :
    );
}

export fn Sinit() void {
    @call(
        .always_inline,
        &gdt.GDT.load,
        .{
            @constCast(&GDT),
        }
    );
    @call(
        .always_inline, 
        &apic.lapic.enableLAPIC,
        .{}
    );

    // Usamos primeiro o assert para entrar no reset junto do LevelTriggered. Depois usamos o Deassert para
    // o core sair do reset e ficar pronto para receber um SIPI

    // NOTE: Imagine sendo um botão, quando apertamos(assert), o processador entra em reset. Quando você
    //       solta, o processador sai do reset, como eles são cores secundários, eles não executar o código de cara
    //       como o BSP que executa a BIOS logo de cara, ele apenas fica esperando um SIPI. O Level só é relevante no comando
    //      .Init, todos os outros não usa esse bit. Segundo a intel usar o TriggerMode como Edge, o bit Level é completamente
    //       ignorado, e o comando simplesmente não vai funcionar
    @call(
        .always_inline,
        &apic.lapic.sendIPI,
        .{
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
        }
    );
    @call(
        .always_inline,
        &apic.lapic.sendIPI,
        .{
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
        }
    );
}

export fn Smain() void {
    @call(
        .always_inline,
        &Sinit,
        .{}
    );
}
