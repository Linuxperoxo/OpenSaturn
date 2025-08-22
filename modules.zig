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

// Como criar modulos para o saturn?
//  Para cria um modulo, alem de usar as interfaces pelo lib/saturn/interfaces/interfaces.zig, voce vai precisar
//  adicionar uma declaraçao "__SaturnModuleDescription__" no arquivo do seu modulo, ele deve ser do tipo 
//  ModuleDescription_T. Feito isso, voce deve adicionar o arquivo com essas declaraçoes dentro de __SaturnAllMods__ 
//  usando o @import()

// --- SATURN MODULES ---
pub const __SaturnAllMods__ = [_]type {
    // Module Location!
    @import("fs/rootfs/module.zig"),
};
