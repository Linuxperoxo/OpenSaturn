// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: options.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// * use_menuconfig_as_ref: Usa o mod.conf.zig como referencia para
//                       habilitar o modulo ou nao. Caso desativado
//                       carrega todos os modulos
//
//
// * ignore_module_with_arch_not_supported: Caso um modulo que nao seja
//                                     suportado pela arquitetura target,
//                                     vai dar um erro de compilacao. Caso
//                                     desativado apenas e ignorado
//
// * allow_dynamic_modules_load: Permite carregar modulos de forma dinamica (not working)
//                            Modulos dinamicos seram carregados de forma separada dos
//                            modulos linkados ao kernel direto na compilacao, isso e
//                            importante para evitar possiveis problemas de seguranca
//
// * force_module_arch_overrider: Espera que a arquitetura tenha o field overrider != null,
//                             o field e usado para sobreescrever o menuconfig
//
// * ignore_overrider_if_no_exist: Caso force_module_arch_overrider = true mas a arquitetura nao tenha
//                             o field overrider != null, essa configuracao diz ou nao se isso vai
//                             causar erro de compilacao, caso ignore_overrider_if_no_exist = false, simplesmente
//                             ignoramos esse fato, e usamos o menuconfig do jeito que esta, caso contrario, temos
//                             o erro de compilacao
//
// * ignore_module_collision: Ignora modulos repetidos, caso contrario, ocorre um erro em comptime

pub const use_menuconfig_as_ref: bool = true;
pub const ignore_module_with_arch_not_supported: bool = true;
pub const allow_dynamic_modules_load: bool = true; // TODO:
pub const force_module_arch_overrider: bool = true;
pub const ignore_overrider_if_no_exist: bool = true;
pub const ignore_module_collision: bool = false;
pub const ignore_fault_no_existent_lib: bool = false;
pub const ignore_version_no_found: bool = false;
