// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const drivers: type = @import("saturn/drivers");
pub const cpu: type = @import("saturn/cpu");
pub const libsat: type = @import("saturn/lib");
pub const devices: type = @import("saturn/devices");

pub const video: type = drivers.video;

// callconv(.naked) não tem prólogo e epílogo automáticos é simplesmente fazer uma função do 0,
// o compilador não adiciona o código de prólogo/epílogo para salvar/restaurar registradores ou
// manipular a pilha, como alocações e desalocação. 
//
// linksection(".text.saturn.entry") serve para por essa label em uma section explícita, poderiamos
// usar o @export para isso
//
// export serve para deixar o símbolo vísivel no assembly, ou seja, poderiamos usar o asm volatile(\\call Sentry);
// em qualquer arquivo, já que o símbolo está vísivel em todo o assembly.
export fn Sentry(_: u32) linksection(".text.saturn.entry") callconv(.Naked) noreturn { 
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
    //       usar essas instruções mesmo em um ambiente bare-metal
    asm volatile(
        \\ cli
        \\ movl $0xF00000, %esp

        \\ movl %cr0,     %eax
        \\ andl $0xFFFB,  %eax
        \\ orl  $0x02,    %eax
        \\ movl %eax,     %cr0
        \\ movl %cr4,     %eax
        \\ orl  $1 << 9,  %eax
        \\ orl  $1 << 10, %eax
        \\ mov %eax, %cr4

        \\ pushl $'R'
        \\ call Smain
        \\ jmp  .

    );
}

export fn Smain(_: u8) void {
    // Inicializando GDT
    @call(.always_inline, &cpu.gdt.load, .{
        cpu.gdt.Pointer { // NOTE: Struct resolvida em tempo de compilação
            .Limit = (cpu.gdt.Entries.len * @sizeOf(cpu.gdt.Entry)) - 1,
            .First = @intFromPtr(&cpu.gdt.Entries[0]),
        }
    });

    _ = @call(.never_inline, devices.video.videoDevice.deviceDriver.IOctrl.send, .{
            drivers.DriverCommand {
            .command = @as(u8, @intFromEnum(video.VideoCommand.@"clear")),
        }
    });

    _ = @call(.never_inline, devices.video.videoDevice.deviceDriver.IOctrl.send, .{
        drivers.DriverCommand { 
            .command = @as(u8, @intFromEnum(video.VideoCommand.@"write")),
            .args = @constCast(&[_:0]u8{'H', 'e', 'l', 'l', 'o',',', ' ', 'W', 'o', 'r', 'l', 'd', '!'}),
        }
    });
}
