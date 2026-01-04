// fusium é um sistema de "patch" do opensaturn,
// é uma forma de adicionar, ou substituir, código
// do core, ele é algo bem próximo do smll, mas pode
// ser usado diretamente no núcleo, não apenas para
// os módulos. Abaixo vai um exemplo:

// digamos que o kernel vai começar a ter suporte a
// vfs hardened, mas temos algumas arquiteturas que
// não vão usar o hardened, com o fusium, podemos
// fazer isso de uma maneira bem interessante e sem
// precisar modificar o código do núcleo, apenas
// criar um fusioner hardened

const fusium: type = @import("root").interfaces.fusium;
const main: type = @import("main.zig"); // core code não hardened
const hardened: ?type = fusium.fetch_fusioner("hardened/vfs"); // fusioner code
// caso o fusioner não esteja adicionado, retorna null, mas depende da config do fusium
const impl: type = hardened orelse main;

pub const write = impl.write;
pub const read = impl.read;
pub const unlink = impl.unlink;
pub const mount = impl.mount;
pub const umount = impl.umount;
pub const create = impl.create;
pub const mkdir = impl.mkdir;
pub const chmod = impl.chmod;
pub const chown = impl.chown;
pub const touch = impl.touch;

// por mais que isso crie 2 bases de código, ainda sim vejo muitas vantagens nisso.
// Mas o fusium não serve somente para substituir código, mas também para criar novas
// coisas para o kernel, um exemplo é o próprio ktask, que poderia sim não ser um fusioner,
// mas como é um recurso que não é obrigatório, mas pode ser usado pelo core, ele se tornou
// um fusioner, um fusioner é isso, um código não obrigatório mas que pode ser usado pelo núcleo,
// como se fosse módulos para o core do kernel

// uma coisa bem interessante de saber, é que o fusium tem um menuconfig, e a arquitetura tem o poder
// de fazer um override no menuconfig global do fusium, você pode dar uma olhada em docs/arch/arch.zig

// o fusium tem algumas opções interessantes em config/fusium/options.zig

// ====================================================================================================

// agora vamos ver como criar e adicionar um fusium ao kernel, ele segue a mesma ideia dos módulos

const fusium: type = @import("root").interfaces.fusium;

// assim como os módulos, precisamos adicionar uma decl, para fusium usamos __SaturnFusiumDescription__
pub const __SaturnFusiumDescription__: fusium.FusiumDescription_T = .{
    .name = "my_fusioner", // nome do fusioner
    // header informativo
    .author = "Linuxperoxo",
    .contributors = &[_][]const u8 {
        "contributor0",
        "contributor1",
        "contributor2",
    },
    .description = "Example Fusioner",
    // o field init pode causar algumas dúvidas, uma delas é por quê
    // adicionar/substituir código do core do kernel iria precisar
    // de uma função init igual um módulo? Essa na verdade, é uma parte
    // bem interessante, e que já tem exemplo de uso real no ktask, que por
    // sinal, vamos usar como exemplo. O ktask escuta o evento do APIC, PIC ou
    // qualquer timer de interrupção, para escutar ele usa os events do kernel,
    // ou seja, ele cria um listener para isso, só que temos 2 problemas, quando
    // vamos chamar a função para adicionar o listener a um evento, e como vamos
    // adicionar o listener a um evento que vem de um módulo? A solução foi adicionar
    // 2 fields aqui, o .init e o .order, então a função do init do ktask adiciona um
    // listener ao evento do timer
    .init = null,
    // .before: chama init antes de qualquer inicialização dos módulos
    // .after: chama o init após todos os módulos serem carregados
    .order = .after, // não tem impacto nenhum quando init == null
    // arquiteturas que o fusioner suporta
    .arch = &[_]fusium.FusiumDescription_T.Target_T {
        .i386,
        .amd64,
        .arm,
        .riscv64,
    },
    // fusioner
    .fusioner = @import("my_fusioner.zig"),
    .flags = .{
        // bloqueia o uso desse fusioner
        .blocked = 0,
    },
};

// depois de definir o __SaturnFusiumDescription__, você deve colocá-lo no
// arquivo fusioners.zig
