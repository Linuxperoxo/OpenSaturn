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
//
// * ForceModuleArchOverrider: Espera que a arquitetura tenha o field overrider != null,
//                             o field e usado para sobreescrever o menuconfig
//
// * IgnoreOverriderIfNoExist: Caso ForceModuleArchOverrider = true mas a arquitetura nao tenha
//                             o field overrider != null, essa configuracao diz ou nao se isso vai
//                             causar erro de compilacao, caso IgnoreOverriderIfNoExist = false, simplesmente
//                             ignoramos esse fato, e usamos o menuconfig do jeito que esta, caso contrario, temos
//                             o erro de compilacao
//
// * IgnoreModulePointerCollision: Ignora modulos repetidos, caso contrario, ocorre um erro em comptime

pub const UseMenuconfigAsRef: bool = true;
pub const IgnoreModuleWithArchNotSupported: bool = true;
pub const AllowDynamicModulesLoad: bool = true; // TODO:
pub const ForceModuleArchOverrider: bool = true;
pub const IgnoreOverriderIfNoExist: bool = true;
pub const IgnoreModuleCollision: bool = false;
