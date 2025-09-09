// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: options.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// * UseMenuconfigAsRef: Usa o mod.conf.zig como referencia para
//                       habilitar o modulo ou nao. Caso desativado
//                       carrega todos os modulos
//

// * IgnoreModuleWithArchNotSupported: Caso um modulo que nao seja
//                                     suportado pela arquitetura target,
//                                     vai dar um erro de compilacao. Caso
//                                     desativado apenas e ignorado

// * EnableSafeMode: Caso ativo, nenhum modulo sera carregado, e todas as outras
//                   opcoes sao ignorada

pub const UseMenuconfigAsRef: bool = true;
pub const IgnoreModuleWithArchNotSupported: bool = false;
pub const EnableSafeMode: bool = false;
