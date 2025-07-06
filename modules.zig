// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modules.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo serve para o kernel detectar os modulos
// que devem ser linkados a ele. Como o kernel nao depende
// de nenhum modulo, se nao tiver um intermediario como esse,
// nenhum modulo seria iniciado pelo kernel, isso facilita tanto
// a implementaçao de novos modulos tanto a legibilidade, imagine
// sempre que fossemos colocar um novo modulo tivessemos que ir no
// codigo fonte do kernel e adicionar a chamada ao modulo explicitamente.

// Como Usar?
//  Para adicionar um modulo ao kernel voce deve criar seu modulo usando 
//  as interfaces disponibilizadas para a sua criaçao, para isso use o arquivo
//  lib/saturn/interfaces/interfaces.zig no seu arquivo zig para ter todas as
//  interfaces. Logo depois de criar seu modulo corretamente, voce vai precisar
//  linkar ele no kernel, para fazer isso voce deve usar a struct LinkModInKernel,
//  use @import(lib/saturn/interfaces/interfaces.zig).module.LinkModInKernel, agora
//  deve adicionar o seguinte codigo no seu modulo: 
//
//  pub const __linkable__: LinkModInKernel = .{
//      init = init, // Aqui voce deve colocar a funçao init do seu modulo
//  };
//
//  Feito isso, voce deve adicionar o arquivo do seu modulo dentro do array "modules"
//  dentro desse arquivo. O arquivo que voce for colocar ali deve ter o __linkable__
//  visivel dentro dele.

const LinkInKernel: type = @import("root").interfaces.module.LinkModInKernel;

pub const modules = [_]type{
    @import("fs/rootfs/module.zig"),
};

pub fn callLinkableMods() void {
    inline for(modules) |module| {
        if(@hasDecl(module, "__linkable__")) {
            if(@TypeOf(module.__linkable__) == LinkInKernel) {
                @call(.never_inline, module.__linkable__.init, .{}) catch {
                };
                continue;
            }
        }
        @compileError("Error");
    }
}
