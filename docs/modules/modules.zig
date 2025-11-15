// atribuir um modulo ao OpenSaturn e uma tarefa
// que nao exige tantos passos, mas deve ser feito
// com atencao

// a primeira coisa que voce deve fazer e descrever seu
// modulo, voce pode fazer isso declarando __SaturnModuleDescription__,
// ele deve ser do tipo ModuleDescription_T, voce pode olhar essa struct
// em lib/saturn/kernel/interfaces/modules.zig

// seu modulo runtime fica asim
const Mod_T: type = @import("root").interfaces.module.Mod_T;
// voce pode pegar o ModuleDescription_T assim:
const ModuleDescription_T: type = @import("root").interfaces.module.ModuleDescription_T;
// agora voce pode pegar o ModuleDescriptionTarget_T assim:
const ModuleDescriptionTarget_T: type = @import("root").interfaces.module.ModuleDescriptionTarget_T;
// e para error de modulo:
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;

// tipos para modulo fs
const Fs_T: type = @import("root").interfaces.fs.Fs_T;
const FsErr_T: type = @import("root").interfaces.fs.FsErr_T;
const Superblock_T: type = @import("root").core.vfs.interfaces.Superblock_T;

// ModuleDescriptionTarget_T serve para informar o sistema de modulos do kernel
// quais arquiteturas seu modulo suporta

// __SaturnModuleDescription__ e usado somente na compilacao, voce
// literalmente descreve como se modulo vai ser inicializado e montado
// no comptime, o modulo usando em runtime vai usar o tipo Mod_T

// o sistema de modulos exige que o nome seja extamente __SaturnModuleDescription__
pub const __SaturnModuleDescription__: ModuleDescription_T = .{
    // aqui e o nome do seu modulo, esse nome sera usado mais tarde. Evite espacos,
    // de um nome como se estivesse declarando uma variavel
    .name = "my_fs",
    // aqui voce pode definir 2 coisas
    // * unlinkable: o modulo nao sera carregado, ele nem vai existir no kernel
    // * linkable: ele e carregado e inicializado
    // * dinamic: ele e apenas carregado, mas para iniciar sera usando inmod
    .load = .linkable,
    // funcao chamada pelo sistema de modulos, e aqui onde voce
    // deve preparar seu modulo
    .init = &init,
    // aqui e o tipo do seu modulo. Como o sistema de modulos foi feito totalmente
    // pensando no comptime, aqui e uma parte bem importante para ele saber que parte
    // do kernel e responsavel por esse modulo, essa union tem todos o tipos de modulos
    // possiveis, voce pode olhar com mais detalhes em lib/saturn/interfaces/modules.zig. 
    // Aqui vou usar de exemplo um modulo de filesystem
    .type = .{
        .filesystem = .{
            // temos 2 possibilidades aqui
            // * compile: vai montar logo na compilacao, ou seja, o kernel vai iniciar ja com
            // esse fs montado, extremamente importante para rootfs por exemplo
            // * dinamic: o fs nao e montado, apenas se voce executar o mount -t my_module /usr por exemplo
            .compile = "/" // pode dar erro caso um sistema de arquivo ja esteja montado em /
        }
    },
    // aqui voce descreve quais arquiteturas tem suporte ao seu modulo, nao se preocupe com
    // arquiteturas nao suportadas, seu modulo nem sera carregado para elas, o sistema de modulos
    // se encarrega dessa preocupacao
    .arch = &[_]ModuleDescriptionTarget_T {
        .i386,
        .amd64,
        .arm,
        .avr,
        .riscv64,
        .xtensa,
    },
};

const my_module: *const Mod_T = &Mod_T {
    // aqui e o nome que vai aparecer no lsmod
    .name = "my_fs",
    // aqui e apenas um header com informacoes
    .desc = "My Module For OpenSaturn :^)",
    .author = "Linuxperoxo",
    .version = "1.0-1",

    .type = .filesystem,
    // funcao chamada na inicializacao do modulo
    .init = &init,
    // funcao chamada no exit do modulo
    .exit = &exit,
    // aqui o private pode ser diferentes tipos, vai depender justamente
    // do tipo de modulo que voce esta fazendo, caso fosse um driver iria
    // usar interfaces.drivers
    .private = @constCast(&Fs_T {
        // para saber o que cada field desse faz, voce deve olhar
        // lib/saturn/interfaces/fs.zig
        .name = "my_fs",
        .flags = .R,
        .mount = myfs_mount,
        .unmount = myfs_umount,
    }),
};

// feito isso, basta adicionar o arquivo la em module.zig, dentro
// de __SaturnAllMods__, voce usa o @import passando o arquivo que
// tem a declaracao __SaturnModuleDescription__

// depois disso, existe um pequeno detalhe, o menuconfig do OpenSaturn,
// se voce nunca compilou o kernel linux, imagine o menuconfig sendo um
// menu onde voce diz se aquele modulo vai ser adicionado ao kernel ou nao.
// va para config/modules/menuconfig.zig, la voce deve colocar exatamente o
// __SaturnModuleDescription__.name, e definir ele como .yes ou .no. Agora
// e oficial, seu modulo esta pronto para funcionar no OpenSaturn, agora fica
// por sua conta criar a implementacao do seu modulo :^)

fn init() ModErr_T!void {
    @call(.never_inline, &@import("root").interfaces.module.inmod, .{
        my_module
    }) catch |err| return err;
}

fn exit() ModErr_T!void {

}

pub fn myfs_mount() FsErr_T!Superblock_T {
    return FsErr_T.AllocInternal;
}

pub fn myfs_umount() FsErr_T!void {

}
