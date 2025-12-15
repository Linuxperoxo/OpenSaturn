// atribuir um módulo ao OpenSaturn é uma tarefa
// que não exige tantos passos, mas deve ser feita
// com atenção

// a primeira coisa que você deve fazer é descrever seu
// módulo, você pode fazer isso declarando __SaturnModuleDescription__,
// ele deve ser do tipo ModuleDescription_T, você pode olhar essa struct
// em lib/saturn/kernel/interfaces/modules.zig

// seu modulo runtime fica asim
const Mod_T: type = @import("root").interfaces.module.Mod_T;
// voce pode pegar o ModuleDescription_T assim:
const ModuleDescription_T: type = @import("root").interfaces.module.ModuleDescription_T;
// agora voce pode pegar o ModuleDescriptionTarget_T assim:
const ModuleDescriptionTarget_T: type = @import("root").interfaces.module.ModuleDescriptionTarget_T;
// e para error de modulo:
const ModErr_T: type = @import("root").interfaces.module.ModErr_T;
// para implementacao de libs
const ModuleDescriptionLibMine_T: type = @import("root").interfaces.module.ModuleDescriptionLibMine_T;
const ModuleDescriptionLibOut_T: type = @import("root").interfaces.module.ModuleDescriptionLibOut_T;

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
    // * dynamic: ele e apenas carregado, mas para iniciar sera usando inmod
    .load = .linkable,
    // funcao chamada pelo sistema de modulos, e aqui onde voce
    // deve preparar seu modulo
    .init = &init,
    // funcao chamada apos o init e o handler do tipo do modulo serem chamado
    .after = &after, // ou null 
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
            // * dynamic: o fs nao e montado, apenas se voce executar o mount -t my_module /usr por exemplo
            .compile = "/" // pode dar erro caso um sistema de arquivo ja esteja montado em /
        }
    },
    // isso aqui e novidade na versao 0.2.*, agora voce pode garantir
    // que seu modulo vai ser carregado depois de todos os outros, basta
    // colocar aqui, isso tambem vai garantir que esses modulos existam
    .deps = &[_][]const u8 { // caso nao tenha dep so deixar .deps = null,
        // cuidado com deps circular, como tudo e resolvido no comptime,
        // ele precisa ser simples o suficiente e tambem e uma parte que
        // esta funcionando perfeitamente, mas sempre vai exitir melhorias,
        // e uma delas e adicionar detect de deps circular de mais niveis
        "my_other_fs",
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
    // voce pode ver sobre as flags em kernel/core/module/types.zig
    .flags = .{
        .call = .{
            .after = 1,
            .handler = 1,
        }
    },
    // Uma das coisas que o OpenSaturn sempre levou muito a sério foi a questão do mantenedor
    // do módulo não precisar se preocupar com a complexidade de adicionar seu módulo ao OpenSaturn,
    // e, sem dúvidas, as libs mines e outside vão ajudar demais. Agora os módulos têm a capacidade
    // de expor algumas partes do seu código para outros módulos. Isso é uma coisa muito interessante
    // se for parar para pensar, já que código de módulo nunca deve estar diretamente no núcleo do kernel,
    // ou em suas libs. Isso porque o kernel deve ser 100% capaz de rodar sem aquele módulo. Se ele não é capaz,
    // isso não é um módulo, e sim algo do núcleo. O conceito de mines e outside só pode ser implementado graças
    // ao Zig, obrigado por isso, Zig :^).
    .libs = .{
        // mines sao as libs que voce como modulo implementa para outros modulos, voce pode ter varias libs aqui
        .mines = &[_]ModuleDescriptionLibMine_T {
            ModuleDescriptionLibMine_T {
                .name = "my_super_lib0", // os outros modulos vao procurar por esse nome
                .lib = @import("my_super_lib0.zig"), // aqui voce pode usar o @import ou montar uma struct {}
                .whitelist = &[_][]const u8 {
                    "mod0",
                    "mod1",
                    "mod2",
                },
                .flags = .{
                    .whitelist = 1, // somente modulos na whitelist
                    .enable = 1, // lib ta habilitada e pode ser usada
                },
            },
            ModuleDescriptionLibMine_T {
                .name = "my_super_lib1",
                .lib = @import("my_super_lib1.zig"),
                .whitelist = &[_][]const u8 {
                    "mod3",
                    "mod4",
                },
                .flags = .{
                    .whitelist = 1,
                    .enable = 1,
                },
            },
            ModuleDescriptionLibMine_T {
                .name = "my_super_lib2",
                .lib = @import("my_super_lib2.zig"),
                .whitelist = null,
                .flags = .{
                    .whitelist = 0, // caso .whitelist == null deixe essa flag como 0
                    .enable = 1,
                },
            },
        },
        // outside sao as libs que voce pode pegar de outros modulos
        .outside = &[_]ModuleDescriptionLibOut_T {
            ModuleDescriptionLibOut_T {
                .mod = "outside_module", // nome do modulo (ModuleDescription_T.name)
                .lib = "outside_super_lib0", // nome da lib, voce pode ver o mines do modulo e ver qual o nome da lib 
            },
            ModuleDescriptionLibOut_T {
                .mod = "outside_module",
                .lib = "outside_super_lib1",
            },
            ModuleDescriptionLibOut_T {
                .mod = "outside_module",
                .lib = "outside_super_lib2",
            },
        },
    },
};

const outside_libs = r: {
    // * outsides: possui um [_]?type
    // * some_fault: se algum indice de outsides e null some_fault == true
    const outsides, const some_fault = __SaturnModuleDescription__.request_libs()
        catch unreachable; // so retorna erro caso outside.len == 0 ou outside == null
    // Aqui você pode decidir o que fazer caso alguma lib falhe. O índice de outsides se refere ao
    // mesmo índice de __SaturnModuleDescription__.outside. Dificilmente alguma lib vai falhar, só
    // ocorre erro caso o módulo não seja encontrado, ou o módulo seja encontrado, mas a lib não.
    if(some_fault) __SaturnModuleDescription__.abort_compile("some lib failed to be fetched!");
    break :r .{
        .slib0 = outsides[0].?,
        .slib1 = outsides[1].?,
        .slib2 = outsides[2].?,
    };
};

const my_module: *const Mod_T = &Mod_T {
    // aqui e o nome que vai aparecer no lsmod
    .name = "my_fs",
    // aqui e apenas um header com informacoes
    .desc = "My Module For OpenSaturn :^)",
    .author = "Linuxperoxo",
    .version = "1.0-1",
    // atualmente somente para informacao
    .deps = &[_][]const u8 {
        "my_other_fs",
    },
    // tambem apenas para informacao
    .license = .{
        .know = .GPL2_only,
        // ou .other = "{license}"
    },
    .type = .filesystem,
    // funcao chamada na inicializacao do modulo
    .init = &init,
    // esse after nao e garantido ser chamado caso o init de Mot_T falhe, diferentemente do after
    // do ModuleDescription_T, quem sempre sera chamado, mesmo que o init de ModuleDescription_T falhe
    .after = null,
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
    // voce tambem pode ver sobre as flags em kernel/core/module/types.zig
    .flags = .{
        .control = .{
            .anon = 0,
            .call = .{
                .exit = 0,
                .remove = 0,
                .after = 0,
                .init = 0,
            },
        },
        .internal = .{
            .installed = 0,
            .removed = 0,
            .collision = .{
                .name = 0,
                .pointer = 0,
            },
            .call = .{
                .init = 0,
                .exit = 0,
                .after = 0,
            },
            .fault = .{
                .call = .{
                    .init = 0,
                    .after = 0,
                    .exit = 0,
                },
                .remove = 0,
            },
        },
    },
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
    // sempre opte por chamar inmod, nunca chame diretamente o handler do seu modulo, o inmod
    // ja e responsavel por resolver o tipo do modulo e chamar o handler correto
    @call(.never_inline, &@import("root").interfaces.module.inmod, .{
        my_module
    }) catch |err| return err;
}

fn after() ModErr_T!void {

}

fn exit() ModErr_T!void {

}

pub fn myfs_mount() FsErr_T!Superblock_T {
    return FsErr_T.AllocInternal;
}

pub fn myfs_umount() FsErr_T!void {

}
