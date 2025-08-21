// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modules.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("modules.config.zig");

pub const ModuleDescriptionTarget_T: type = arch.target_T;
pub const ModuleDescription_T: type = struct {
    name: ?[]const u8, // usado no futuro
    need: ?bool, // usado no futuro
    init: *const fn() anyerror!void, // ponteiro para a funcao init
    arch: []const ModuleDescriptionTarget_T, // arch suportadas
    type: union(enum) {
        driver: void,
        syscall: void,
        interrupt: void,
        irq: void,
        fs: union(enum) {
            compile: []const u8, // faz a montagem de forma direta no kernel (fstab permanente)
            dinamic: void, // sera adicionado ao kernel, mas sua montagem acontece em runtime
        },
    },
};

// Esse arquivo serve para o kernel detectar os modulos
// que devem ser linkados a ele. Como o kernel nao depende
// de nenhum modulo, se nao tiver um intermediario como esse,
// nenhum modulo seria iniciado pelo kernel, isso facilita tanto
// a implementaçao de novos modulos tanto a legibilidade, imagine
// sempre que fossemos colocar um novo modulo tivessemos que ir no
// codigo fonte do kernel e adicionar a chamada ao modulo explicitamente.

// Como criar modulos para o saturn?
//  Para cria um modulo, alem de usar as interfaces pelo lib/saturn/interfaces/interfaces.zig, voce vai precisar
//  adicionar uma declaraçao "__SaturnModuleDescription__" no arquivo do seu modulo, ele deve ser do tipo 
//  ModuleDescription_T. Feito isso, voce deve adicionar o arquivo com essas declaraçoes dentro de __SaturnAllMods__ 
//  usando o @import()

// --- SATURN MODULES ---
pub const __SaturnAllMods__ = [_]type {
    @import("fs/rootfs/module.zig"),
};

comptime {
    for(__SaturnAllMods__) |M| {
        if(!@hasDecl(M, "__SaturnModuleDescription__")) {
            @compileError(
                "__SaturnModuleDescription__ is not defined in the module file" ++ @typeName(M)
            );
        }
    }
}

pub fn callLinkableMods() void {
    inline for(__SaturnAllMods__) |M| {
        for(M.__SaturnModuleDescription__.arch) |supported| {
            if(arch.__SaturnTarget__ == supported) {
                @call(.never_inline, M.__SaturnModuleDescription__.init, .{}) catch {
                }; continue;
            }
        }
        if(!config.IgnoreModuleWithArchNotSupported) {
            @compileError("module file " ++ @typeName(M) ++ " is not supported by target architecture " ++ @tagName(arch.__SaturnTarget__));
        }
    }
}
