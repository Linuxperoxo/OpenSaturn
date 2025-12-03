// a forma como o OpenSaturn lida com a multiarch é um grande desafio,
// organizar o kernel para que funcione para diferentes arquiteturas
// é um trabalho que sempre está sendo aperfeiçoado dentro do kernel,
// atualmente, a arquitetura ainda precisa implementar várias partes do
// kernel, caso você queira criar uma nova arquitetura para o OpenSaturn,
// esse arquivo vai lhe ajudar bastante na sua jornada, pelo menos, espero
// que ajude

// vamos lá, fazer um suporte para uma nova arquitetura para um kernel, sem
// dúvidas, é um grande desafio, você precisa conhecer bem a arquitetura do
// microprocessador, e mais ainda do kernel, aqui no OpenSaturn você vai precisar
// se preocupar apenas com a arquitetura. O OpenSaturn possui um header exclusivo
// para declarações de arquitetura, adicionar a arquitetura exige mais passos que
// adicionar um módulo, mas ainda assim, não são tantos passos

// a primeira coisa antes de começar, é saber onde você vai colocar seus arquivos,
// isso é uma coisa bem importante para o projeto se manter organizado e totalmente
// isolado. Por padrão, usamos o diretório kernel/arch/{arch} para colocar o header da
// arquitetura, usamos os diretórios kernel/entries/{arch}, kernel/interrupts/{arch},
// kernel/physio/{arch} e mm/{arch} como entrada do kernel para aquela arquitetura,
// interrupções da arquitetura, gerenciamento de IO e gerenciamento de memória, mas como
// dito acima, isso são detalhes da arquitetura, o kernel é responsável por tentar padronizar
// o máximo possível esses detalhes da arquitetura.

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

// assim como os modulos, o nome precisa ser exatamente assim, usando o mesmo
// tipo, tudo isso e verificado durante a compilacoa
pub const __SaturnArchDescription__: interfaces.arch.ArchDescription_T = .{
    // caso .usable = false, voce esta falando para o kernel que sua arquitetura
    // ainda nao esta pronta para ser usada, qualquer tentativa de compilar com
    // ela ira ocorrer um erro
    .usable = true,
    // observe que agora temos coisas iguais, mas que fazem
    // coisas completamente diferentes
    //
    // * entry: responsável por ligar o entry da arquitetura,
    // esse entry é extremamente importante, já que é o primeiro
    // código, após o bootloader, a ser executado. Aqui é um lugar
    // bem importante, já que o kernel em si não chama nenhuma função
    // da arquitetura, isso é importante para que a arquitetura tenha
    // total controle sobre ela mesma, então a única responsabilidade
    // do kernel é usar os arquivos da arquitetura, o restante é com
    // ela própria
    .entry = .{
        // como cada parte da arquitetura pode ser bem grande e complexa,
        // deixei o field .maintainer para deixar uma assinatura da pessoa
        // responsável por aquela parte
        .maintainer = "Linuxperoxo",
        // esses próximos 2 fields servem para que o kernel ajude a arquitetura,
        // como? Da seguinte forma: no Zig temos um builtin @export(), ele serve
        // para criarmos labels no assembly para variáveis e funções lá no assembly,
        // o compilador faz isso, mas não vai saber o nome da label que ele deu. Fazendo
        // isso, podemos simplesmente usar .i386.entry no assembly livremente
        .label = ".i386.entry",
        .entry = &entry.entry,
    },
    // * init: é bem parecida com o entry, mas no caso do i386, usamos
    // o init para certos detalhes, novamente, nada disso é realmente obrigatório,
    // tirando o próprio entry, todos os outros são opcionais, isso deixa justamente
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
    // * physio: detalhes do gerenciamento de physio, em versoes futuras provavelmente
    // sera promovido a modulo. Para obter mais detalhes veja kernel/physio/README
    .physio = .{
        .maintainer = "Linuxperoxo",
        .label = ".i386.physio",
        .entry = &physio.physio_init,
        .sync = &physio.physio_sync,
    },
    // aqui temos o .extra e .data, eles sao usados para a arquitetura usar o @export
    // em certas coisas, como seus detalhes de ISA, isso evita ficar colocando @export
    // em varios arquivos diferentes, desse jeito fica tudo em um unico lugar
    .extra = &[_]interfaces.arch.ArchDescription_T.Extra_T {
        .{
            .maintainer = "Linuxperoxo",
            .label = ".i386.gdt",
            .entry = .{
                .c = &physio.physio_init,
                // ou .naked
            },
        },
    },
    // esse .extra e .data resolve um problema bem específico. O compilador
    // não resolve bloco comptime de container não usados diretamente,
    // ou seja, se você apenas usa o @import() e não usa nada dentro
    // daquele container, o bloco comptime nunca será executado, isso
    // pode causar confusão caso você use um @export() dentro de um bloco
    // comptime que nunca será executado, isso provavelmente vai dar erro
    // de symbol not found quando você tentar usar no assembly. Com esses 2
    // fields a arquitetura evita usar em 100% dos casos o @export diretamente
    .data = &[_]interfaces.arch.ArchDescription_T.Data_T {
        .{
            .label = "gdt_struct",
            .section = sections.section_data_persist,
            .ptr = &init.gdt.gdt_struct,
        },
        .{
            .label = "gdt_entries",
            .section = sections.section_data_persist,
            .ptr = &init.gdt.gdt_entries,
        },
        .{
            .label = "idt_struct",
            .section = sections.section_data_persist,
            .ptr = &interrupts.idt_struct,
        },
        .{
            .label = "idt_entries",
            .section = sections.section_data_persist,
            .ptr = &interrupts.idt_entries,
        },
    },
    // outra novidade da 0.2.*. Agora a arquitetura pode forcar
    // um modulo ser habilitado e desabilitado, esse modulo precisa
    // realmente existir e ser suportado pela arquitetura
    .overrider = &[_]interfaces.arch.ArchDescription_T.Overrider_T {
        // esse overrider e muito bom ja que tira a necessidade de alterar
        // diretamente o menuconfig que e global.
        // junto do overrider, temos 2 novas configuracoes config.module
        //
        // * ForceModuleArchOverrider: isso realmente habilita o overrider
        // * IgnoreOverriderIfNoExist: caso seja true, so ignora se um modulo
        // nao existe, mas te tentando ser substituido, caso seja false, isso
        // vai causar um erro de comptime
        .{
            .module = "ke_m_pci",
            .value = .yes, // ou .no para desabilitar
        },
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

// depois de criar a implementar todos os arquivos, precisamos adicionar ela ao kernel,
// isso pode ser feito por 3 arquivos, o primeiro e em config/arch/types.zig, la vamor ter
// um enum:

pub const Target_T: type = enum {
    amd64,
    arm,
    avr,
    xtensa,
    riscv64,
};

// basta colocar sua nova arquitetura, digamos que seja i386

pub const Target_T: type = enum {
    i386,
    amd64,
    arm,
    avr,
    xtensa,
    riscv64,
};

// feito isso, vamos precisar ir em saturn.zig, la temos uma grande struct chamada
// Architectures, dentro dela temos todas as arquiteturas do kernel, e seus arquivos,
// voce deve fazer a mesma coisa, seguindo a mesma ideia, vamos usar de exemplo i386
// navamente

pub const Architectures: type = struct {
    pub const @"i386": type = struct {
        // todos os arquivos da nossa arquitetura
        pub const arch: type = @import("kernel/arch/i386/i386.zig"); // aqui fica o __SaturnArchDescription__
        pub const entry: type = @import("kernel/entries/i386/entry.zig");
        pub const init: type = @import("kernel/init/i386/init.zig");
        pub const interrupts: type = @import("kernel/interrupts/i386/interrupts.zig");
        pub const linker: type = @import("linkers/i386/linker.zig");
        pub const physio: type = @import("kernel/physio/i386/physio.zig");
        pub const mm: type = @import("mm/i386/mm.zig");
        // essa struct lib provavalmente no futuro sera opcional existir, mas atualmente
        // ela e obrigatoria
        pub const lib: type = struct {
            pub const kernel: type = @import("lib/saturn/kernel/arch/i386/lib.zig");
            pub const userspace: type = @import("lib/saturn/userspace/i386/lib.zig");
        };
    };

    pub const amd64: type = struct {
        pub const arch: type = @import("kernel/arch/amd64/amd64.zig");
        pub const entry: type = @import("kernel/entries/amd64/entry.zig");
        pub const interrupts: type = @import("kernel/interrupts/amd64/interrupts.zig");
        pub const linker: type = @import("linkers/amd64/linker.zig");
        pub const mm: type = @import("mm/amd64/mm.zig");
        pub const lib: type = struct {
            pub const kernel: type = @import("lib/saturn/kernel/arch/amd64/lib.zig");
            pub const userspace: type = @import("lib/saturn/userspace/amd64/lib.zig");
        };
    };
};

// e por fim, modificar o SelectedArch

const SelectedArch: type = switch(config.arch.options.Target) {
    .i386 => Architectures.i386,
    .amd64 => Architectures.amd64,
};

// agora a arquitetura já existe, e já é reconhecida pelo kernel, agora só precisa
// de um detalhe: modificar o build.zig, essa parte não vai mais ser necessária em
// versões futuras, não gosto da ideia de modificar o build.zig, e ainda mais deixá-lo
// complexo. O que você deve fazer é exatamente o que você fez com SelectedArch arch

pub const target: std.Target.Cpu.Arch = switch(SaturnArchConfig.options.Target) {
    // voce pode olhar std.Target.Cpu.Arch, e ver qual arquitetura deve ser passada
    // para o compilador
    // kernel => Zig Target
    .i386 => .x86,
    .amd64 => .x86_64,
};

// pronto, agora sua arquitetura esta pronta e funcionando perfeitamente no saturn
