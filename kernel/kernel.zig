// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kernel.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const cpu: type = @import("saturn/kernel/cpu");
pub const supported: type = @import("saturn/kernel/arch/supported");
pub const entries: type = @import("saturn/kernel/arch/entries");
pub const interrupts: type = @import("saturn/kernel/arch/interrupts");
pub const core: type = @import("saturn/kernel/core");
pub const exported: type = @import("saturn/kernel/exported");
pub const memory: type = @import("saturn/kernel/memory");
pub const interfaces: type = @import("saturn/kernel/modules/interfaces");
pub const debug: type = @import("saturn/kernel/debug");
pub const supervisor: type = @import("saturn/kernel/supervisor");
pub const kernel: type = @import("saturn/kernel/lib"); // NOTE: Possibly obsolete in the future
pub const userspace: type = @import("saturn/userspace/lib");
pub const config: type = @import("saturn/kernel/config");
pub const modules: type = @import("saturn/kernel/modules");

const loader: type = @import("saturn/kernel/loader");

// NOTE: Para obter mais detalhes de como funciona a inicializacao do
// kernel voce pode olhar o arquivo kernel/loader.zig, nele vai ter toda
// a logica de comptime e runtime para inicializar e resolver os detalhes
// da inicializacao do kernel. O motivo de ter um arquivo separado para isso
// e pela organizacao, eu prefiro deixar esse arquivo mais limpo, justamente
// para facilitar a leitura e o entendimento do fluxo do kernel

// O fluxo do kernel funciona da seguinte maneira:
//  * Primeiro vamos ter o entry de tudo, que deve ser definido dentro
//    da arquitetura alvo. O x86 tem seu entry em kernel/arch/x86/x86.zig
//  * O linker.ld e extremamente importante nesse caso, ja que ele vai colocar
//    o header do bootloader, no caso do x86 e o AtlasB, voce pode encontrar a
//    definicao do header do AtlasB no mesmo arquivo passado acima
//  * E pronto, feito isso o bootloader apos carregar a imagem do kernel,
//    ele vai passar o controle para a fn entry. O entry deve obrigatoriamente
//    chamar a fn main do kernel, feito isso, o kernel vai fazer o resto

export fn init() void {
    // SaturnArch e resposavel por chamar a fn init da arquitetura alvo,
    // ela e responsavel tambem por resolver o tipo de interrupcao usada
    // pela arquitetura, a chamada da fn init para a interrupcao tambem
    // e feita aqui

    // Deixar essa chamada como .always_inline, causa um bug de exported symbol collision.
    // ele tenta resolver o bloco comptime mais 2 uma vez por algum motivo.
    @call(.never_inline, &loader.SaturnArch, .{});
}

export fn main() void {
    // init do kernel
    @call(.always_inline, &init, .{});
    // Depois da arquitetura resolver todos os seus detalhes, podemos iniciar
    // os modulos linkados ao kernel
    @call(.always_inline, &loader.SaturnModules, .{});
}
