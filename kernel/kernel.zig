// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kernel.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const saturn: type = @import("saturn");

pub const cpu: type = saturn.cpu;
pub const core: type = saturn.core;
pub const memory: type = saturn.memory;
pub const interfaces: type = saturn.interfaces;
//pub const debug: type = saturn.debug;
pub const supervisor: type = saturn.supervisor;
pub const kernel: type = saturn.lib.kernel;
pub const userspace: type = saturn.lib.userspace;
pub const utils: type = saturn.lib.utils;
pub const config: type = saturn.config;
pub const modules: type = saturn.modules;
pub const step: type = struct {
    pub const saturnGetPhase = saturn.step.saturnGetPhase;
};

const loader: type = saturn.loader;

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

comptime {
    @export(&@"saturn.main", .{
        .name = "saturn.main",
        .section = ".text.saturn",
        .linkage = .strong,
        .visibility = .default,
    });
}

fn @"saturn.main"() callconv(.c) void {
    // SaturnArch e resposavel por chamar a fn init da arquitetura alvo,
    // ela e responsavel tambem por resolver o tipo de interrupcao usada
    // pela arquitetura, a chamada da fn init para a interrupcao tambem
    // e feita aqui

    // Aqui existe um pequeno detalhe, bem interessante por sinal.
    // Quando passamos um ponteiro para uma funcao conhecida em tempo
    // de compilacao para o @call, o compilador precisa considerar que
    // esse ponteiro pode ser usado em runtime, por exemplo, se carregamos
    // o endereco da funcao em um registrador, para ter um endereco ela precisa
    // estar no binário, ou seja, mesmo que estajamos pedindo para colocar como
    // inline, o compilador cria um .never_inline para essa funcao ja que usamos
    // o endereço dela, mas so vamos ter uma copia da funcao como .never_inline
    // se realmente o endereco dela seja usado em runtime. O maior problema disso
    // nesse caso, e usar um bloco comptime dentro da funcao, nesse caso ele iria
    // ser executado 2 vezes, e nessa funcao o bloco comptime nao pode ser chamado
    // 2 vezes, que e @export(), executar ele usando o mesmo nome de simbolo causa um
    // exported symbol collision, como resolver isso então? Simplemente usando o .never_inline
    // ou usando somente loader.SaturnArch, isso evita de criar um possivel .never_inline
    // implicito
    @call(.always_inline, loader.SaturnArch, .{});
    @call(.always_inline, saturn.step.saturnSetPhase, .{
        .init
    });

    // Depois da arquitetura resolver todos os seus detalhes, podemos iniciar
    // os modulos linkados ao kernel
    @call(.always_inline, loader.SaturnModules, .{});
    @call(.always_inline, saturn.step.saturnSetPhase, .{
        .runtime
    });
}
