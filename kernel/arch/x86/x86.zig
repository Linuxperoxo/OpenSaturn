// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: cpu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const gdt: type = @import("gdt.zig");
pub const apic: type = @import("apic.zig");
pub const msr: type = @import("msr.zig");
//pub const pic: type = @import("pic.zig");

pub const __arch_maintainer__: []const u8 = "Linuxperoxo";
pub const __arch_linker_build__: []const u8 = "x86/linker.ld";
pub const __arch_usable__: bool = true;
pub const __arch_supervisor__: bool = true;

comptime {
    @export(&entry, .{
        .name = "entry",
    });
}

// callconv(.naked) não tem prólogo e epílogo automáticos é simplesmente fazer uma função do 0,
// o compilador não adiciona o código de prólogo/epílogo para salvar/restaurar registradores ou
// manipular a pilha, como alocações e desalocação.
//
// linksection(".text.saturn.entry") serve para por essa label em uma section explícita, poderiamos
// usar o @export para isso
//
// export serve para deixar o símbolo vísivel no assembly, ou seja, poderiamos usar o asm volatile(\\call Sentry);
// em qualquer arquivo, já que o símbolo está vísivel em todo o assembly.
pub fn entry() linksection(".text.entry") callconv(.naked) noreturn {
    asm volatile(
        \\ cli
        \\ movl $0xF00000, %esp
        \\ call init
        \\ call main
        \\ jmp .
    );

    // AtlasB Headers
    //
    // Esse Headers deve ser colocado no inicio do binario, em 
    // seus primeiros 17 bytes.
    //
    // * AtlasMagic: Numero magico que fala para o Atlas que e uma imagem valida
    // * AtlasLoadDest: Endereço de memoria fisico onde o binario vai ser carregado
    // * Offset dentro do arquivo onde fica o entry do codigo, o atlas vai dar jump nesse offset
    // * AtlasImgSize: Tamanho total do binario em bytes
    // * AtlasVMode: Modo de video que deve ser colocado
    // * AtlasFlags: Flags gerais para o Atlas, consulte a documentaçao no fonte do atlas NOTE:https://github.com/Linuxperoxo/AtlasB/blob/master/src/atlas.s
    asm volatile(
        \\  .equ AtlasMagic, 0xAB00
        \\  .equ AtlasLoadDest, 0x1000000
        \\  .weak AtlasImgSize
        \\  .equ AtlasVMode, 0x1000
        \\  .equ AtlasFlags, 0b00000001
        \\  .section .opensaturn.data.atlas.header,"a",@progbits
        \\  .type AtlasHeaders,@object
        \\ AtlasHeaders:
        \\   .word AtlasMagic
        \\   .long AtlasLoadDest
        \\   .long entry - AtlasLoadDest
        \\   .long AtlasImgSize
        \\   .word AtlasVMode
        \\   .byte AtlasFlags
        :
        :
        :
    );
}

pub fn init() void {
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

    // NOTE: Habilitar o SSE e FPU e importante ja que o compilador pode usar esse tipo de 
    //       instruçao para otimizaçao, ainda mais se usarmos o tipo @Vector
    asm volatile(
        \\ movl %cr0,      %eax
        \\ andl $0xFFFB,   %eax
        \\ orl  $0x02,     %eax
        \\ movl %eax,      %cr0
        \\ movl %cr4,      %eax
        \\ orl  $1 << 9,   %eax
        \\ orl  $1 << 10,  %eax
        \\ movl %eax,      %cr4
        :
        :
        :
    );

    @call(.always_inline, &gdt.GDT.load, .{@constCast(&gdt.GDT {
        .Entries = @constCast(&[_]gdt.GDTEntry {
            @call(.compile_time, &gdt.GDT.newEntry, .{
                0x00,
                0x00,
                0x00,
                0x00,
            }),
            @call(.compile_time, &gdt.GDT.newEntry, .{
                0x00,
                0xFFFF,
                0x0C,
                0x9A,
            }),
            @call(.compile_time, &gdt.GDT.newEntry, .{
                0x00,
                0xFFFF,
                0x0C,
                0x92,
            }),
        }),
    })});

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
