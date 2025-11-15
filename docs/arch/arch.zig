// a forma como o OpenSaturn lita com a multiarch e um grande desafio,
// organizar o kernel para que funciona para diferentes arquiteturas
// e um trabalho que sempre esta sendo aperfeicoado dentro do kernel,
// atualmente, a arquitetura ainda precisa implementar varias partes do
// kernel, caso voce queira criar uma nova arquitetura para o OpenSaturn
// esse arquivo vai lhe ajudar bastante na sua jornada, pelo menos, espero
// que ajude

// vamos la, fazer um suporte para uma nova arquitetura para um kernel, sem
// duvidas, e um grande desafio, voce precisa conhecer bem a arquitetura do
// microprocessador, e mais ainda do kernel, aqui no OpenSaturn voce vai precisar
// se preocupar apenas para a arquitetura. O OpenSaturn possui um header exclusivo
// para declaracoes de arquitetura, adicionar a arquitetura exige mais passos que
// adicionar um modulo, mas ainda sim, nao sao tantos passos

// a primeira coisa antes de comecar, e saber onde voce vai colocar seus arquivos,
// isso e uma coisa bem importante para o projeto se manter organizado e totalmente
// isolado. Por padrao, usamos o diretorio kernel/arch/{arch} para colocar o header da
// arquitetura, usamos os diretorios kernel/entries/{arch}, kernel/interrupts/{arch},
// kernel/physio/{arch} e mm/{arch} como entrada do kernel para arquela arquitetura,
// interrupcoes da arquitetura, gerenciamento de IO e gerenciamento de memoria, mas como
// dito acima, isso sao detalhe da arquitetura, o kernel e responsavel por tentar padronizar
// o maximo possivel esses detalhes da arquitetura.

// vou usar de exemplo a arquitetura i386. Vamos comecar observando o primeiro arquivo:

// =================== kernel/arch/i386/i386.zig:

const root: type = @import("root");

// juntamos toda a arquitetura aqui
const entry: type = root.entry; // -> kernel/entries/i386/entry.zig
const init: type = root.init; // -> kernel/init/i386/init.zig
const interrupts: type = root.interrupts; // -> kernel/interrupts/i386/interrupts.zig
const mm: type = root.mm; // -> mm/i386/mm.zig
const interfaces: type = root.interfaces;

// detalhe da arquitetura
pub const linker: type = @import("linker.zig");
pub const sections: type = @import("sections.zig");

// assim como modulo, o nome precisa ser exatamente assim, usando o mesmo
// tipo, tudo isso e verificado durante a compilacoa
pub const __SaturnArchDescription__: interfaces.arch.ArchDescription_T = .{
    // caso .usable = false, voce esta falando para o kernel que sua arquitetura
    // ainda nao esta pronta para ser usada, qualquer tentativa de compilar com
    // ela ira ocorrer um erro
    .usable = true,
    // observe que agora temos coisas iguais, mas que fazem
    // coisas completamente diferente
    //
    // * entry: responsavel por ligar o entry da arquitetura,
    // esse entry e extremamente importante, ja que e o primeiro
    // codigo, apos o bootloader, a ser executado. Aqui e um lugar
    // bem importante, ja que o kernel em si, nao chama nenhuma funcao
    // da arquitetura, isso e importante para que a arquitetura tenha
    // total controle sobre ela mesmo, entao a unica responsabilidade
    // o kernel e usar os arquivos da arquitetura, e restante e com
    // ela propria
    .entry = .{
        // como cada parte da arquitetura pode ser bem grande e complexa,
        // deixei o field .maintainer para deixar uma assinatura da pessoa
        // responsavel por aquela parte
        .maintainer = "Linuxperoxo",
        // esses proximos 2 fields servem para que o kernel ajude a arquitetura,
        // como? Da seguinte forma, no zig temos um builtin @export(), ele serve
        // para criarmos labels no assembly para variaveis e funcoes la no assembly,
        // no compilador faz isso, mas vai saber o nome da label que ele deu, fazendo
        // isso, podemos simplesmente usar .i386.entry no assembly livremente
        .label = ".i386.entry",
        .entry = &entry.entry,
    },
    // * init: e bem parecida com o entry, mas no caso do i386, usamos
    // o init para certos detalhe, novamente, nada disso e realmente obrigatorio,
    // tirando o proprio entry, todos os outros sao opcionais, isso deixa justamente,
    // a arquitetura tendo total controle sobre si
    .init = .{
        .maintainer = "Linuxperoxo",
        .label = ".i386.init",
        .entry = &init.init,
    },
    // * interrupts: aqui e como a arquitetura configura e gerencia as interrupcoes
    .interrupts = .{
        .maintainer = "Linuxperoxo",
        .label = ".i386.interrupts",
        .entry = &interrupts.idt_init,
    },
    // * interrupts: aqui e como a arquitetura configura e gerencia a memoria
    .mm = .{
        .maintainer = "Linuxperoxo",
        .label = ".i386.mm",
        .entry = &mm.mmu_init,
    },
};

// =================== kernel/entries/i386/entry.zig:

const arch: type = @import("root").arch; // -> kernel/arch/i386/i386.zig
const config: type = @import("root").config;
const kernel: type = @import("root").kernel;
const atlas: type = @import("atlas.zig");

const section_text_loader = arch.sections.section_text_loader;
const section_data_loader = arch.sections.section_data_loader;
const section_data_persist = arch.sections.section_data_persist;

comptime {
    const aux: type = opaque {
        pub fn make_asm_set(comptime name: []const u8, comptime value: u32) []const u8 {
            return ".set " ++ name ++ ", " ++ kernel.utils.fmt.intFromArray(value) ++ "\n";
        }
    };
    // aqui fica um dos detalhe da arquitetura, ela usa o AtlasB, que e o bootloader
    // padrao do OpenSaturn, mas como a arquitetura tem controle sobre si, caso o i386
    // queira suportar o grub tambem, poderia criar um arquivo de configuracao em kernel/arch/i386/config.zig
    // e usar livremente aqui, essa configuracao iria ficar local aqui, mas pretendo fazer uma config global
    // para a arquitetura, assim todos os lugares que usam essa arquitetura poderiam se moldar
    asm(
        aux.make_asm_set("AtlasLoadDest", atlas.atlas_load_dest) ++
        aux.make_asm_set("AtlasVMode", atlas.atlas_vmode) ++
        aux.make_asm_set("AtlasFlags", atlas.atlas_flags) ++
        \\  .set AtlasMagic, 0xAB00
        \\  .weak AtlasImgSize
        \\  .section .opensaturn.data.atlas.header,"a",@progbits
        \\  .type AtlasHeaders,@object
        \\ AtlasHeaders:
        \\   .word AtlasMagic
        \\   .long AtlasLoadDest
        \\   .long .i386.entry - AtlasLoadDest
        \\   .long AtlasImgSize
        \\   .word AtlasVMode
        \\   .byte AtlasFlags
    );
}

// funcoes de entry obrigatoriamente precisam ter o callconv(.naked), isso
// diz ao compilador que essa funcao ele nao pode gerar nenhum tipo de assembly,
// o unico assembly que vai ter aqui vai ser o que dentro de asm volatile();
pub fn entry() linksection(section_text_loader) callconv(.naked) noreturn {
    // nao vamos falar sobre cada implementacao de cada lugar do i386,
    // ja que e bem grande e complexa, mas voce pode olhar, modificar e
    // explorar voce mesmo
    asm volatile(
        \\ cli
        \\ movl %[phys_stack], %esp
        // chegamos ao inicio de tudo. Observe
        // que os nomes la da struct __SaturnArchDescription__
        // sao usados aqui, como dito acima, o kernel resolve
        // usando o @export()
        \\ calll .i386.init
        \\ calll .i386.mm
        // aqui e uma coisa que nao existe la na struct, e como
        // dito, a arquitetura pode e deve fazer esse tipo de coisa,
        // sao detalhes de arquitetura que outras arquitetura podem
        // nao ter
        \\ calll .i386.init.gdt
        \\ calll .i386.interrupts
        // depois de configurar tudo, a arquitetura deve
        // passar o controle para o kernel
        \\ jmp saturn.main
        :
        :[phys_stack] "i" (
            // aqui ela usa a configuracao padrao de enderecos de memoria do kernel, essa configuracao sim
            // e global
            comptime (config.kernel.mem.phys.kernel_stack_base + config.kernel.options.kernel_stack_size)
        ),
         [_] "{edi}" (
            arch.linker.phys_address_opensaturn_data_start
        )
    );
}
