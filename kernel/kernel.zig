// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kernel.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const x86: type = @import("saturn/kernel/arch/x86");
//pub const x86_64: type = @import("saturn/kernel/arch/x86_64");
//pub const arm: type = @import("saturn/kernel/arch/arm");

//pub const core: type = @import("saturn/kernel/core");
//pub const interfaces: type = @import("saturn/lib/interfaces");
//pub const io: type = @import("saturn/lib/io");

pub const arch: type = x86;

// callconv(.naked) não tem prólogo e epílogo automáticos é simplesmente fazer uma função do 0,
// o compilador não adiciona o código de prólogo/epílogo para salvar/restaurar registradores ou
// manipular a pilha, como alocações e desalocação.
//
// linksection(".text.saturn.entry") serve para por essa label em uma section explícita, poderiamos
// usar o @export para isso
//
// export serve para deixar o símbolo vísivel no assembly, ou seja, poderiamos usar o asm volatile(\\call Sentry);
// em qualquer arquivo, já que o símbolo está vísivel em todo o assembly.
export fn entry(_: u32) linksection(".text.entry") callconv(.Naked) noreturn {
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

    // Configurar o SSE/FPU é importante aqui já que o compilador zig pode
    // usar essas instruções mesmo em um ambiente bare-metal

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
        \\ call init
        \\ call main
        \\ jmp .

        :
        :
        :
    );
}

export fn init() void {
    // Todo esse codigo e rodado em comptime para fazer
    // algumas verificaçoes para a arquitetura alvo do kernel
    const typeInfo = init: {
        if(!@hasDecl(arch, "init")) {
            @compileError(
                "target kernel cpu architecture does not have an internal function set to init"
            );
        }
        break :init @typeInfo(@TypeOf(arch.init));
    };
    switch(typeInfo) {
        .@"fn" => {
            if(typeInfo.@"fn".return_type != void or
                typeInfo.@"fn".params.len != 0) {
                @compileError(
                    "init function is expected to be an fn() void"
                );
            }
            // Caso chegue aqui, a chamada dessa funçao e adicionada 
            // no codigo final
            @call(.always_inline, arch.init, .{}); 
        },
        else => {
            @compileError(
                "target kernel cpu architecture does not have an internal function set to init"
            );
        },
    }
}

export fn main() void {
    @call(.always_inline, &init, .{});
}
