// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: init.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").code.arch;

pub const gdt: type = @import("gdt.zig");
pub const apic: type = @import("apic.zig");
pub const msr: type = @import("msr.zig");
//pub const pic: type = @import("pic.zig");

const section_text_loader = arch.sections.section_text_loader;
const section_data_loader = arch.sections.section_data_loader;
const section_data_persist = arch.sections.section_data_persist;

pub fn init() linksection(section_text_loader) callconv(.c) void {
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
        \\ movl %cr0, %eax
        \\ andl $0xFFFB, %eax
        \\ orl  $0x02, %eax
        \\ movl %eax, %cr0
        \\ movl %cr4, %eax
        \\ orl  $1 << 9, %eax
        \\ orl  $1 << 10, %eax
        \\ movl %eax, %cr4
        :
        :
    );
    // Aqui deixamos tudo inline para evitar o uso de linksection para outras funcoes
    // a ideia e que todas as funcoes de entry da arch devem ser 4 funcoes e cada uma
    // com um assembly gigante, assim evitando problemas de endereco virtual e endereco
    // fisico
    @call(.always_inline, apic.apic_config, .{});
}
