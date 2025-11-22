// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: options.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// * UseMenuconfigAsRef: Usa o mod.conf.zig como referencia para
//                       habilitar o modulo ou nao. Caso desativado
//                       carrega todos os modulos
//
//
// * IgnoreModuleWithArchNotSupported: Caso um modulo que nao seja
//                                     suportado pela arquitetura target,
//                                     vai dar um erro de compilacao. Caso
//                                     desativado apenas e ignorado
//
// * AllowDynamicModulesLoad: Permite carregar modulos de forma dinamica (not working)
//                            Modulos dinamicos seram carregados de forma separada dos
//                            modulos linkados ao kernel direto na compilacao, isso e
//                            importante para evitar possiveis problemas de seguranca

pub const UseMenuconfigAsRef: bool = true;
pub const IgnoreModuleWithArchNotSupported: bool = true;
pub const AllowDynamicModulesLoad: bool = true; // TODO:
