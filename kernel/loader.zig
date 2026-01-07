// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: loader.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo e responsavel por 2 coisas, carregar
// recursos do kernel, e fazer verificacoes em comptime

const code: type = @import("root").code;
const codes: type = @import("root").codes;
const arch: type = @import("root").code.arch;
const decls: type = @import("root").decls;
const lib: type = @import("root").lib;
const config: type = @import("root").config;
const supervisor: type = @import("root").supervisor;
const interfaces: type = @import("root").interfaces;

comptime {
    // NOTE: usar assembly inline dentro do nucleo de um kernel e totalmente desencorajado, ja
    // que aquele codigo so funciona apenas para uma arquitetura, ou seja, vamos precisar
    // ter um codigo assembly naquela parte para cada arquitetura, nesse caso, nao tem problema
    // nenhum em usar assembly inline aqui, ja que usamos diretivas, nao instrucoes, isso funciona
    // para assembly de qualquer arquitetura suportada pelo GAS

    // isso aqui realmente precisa ser feito, nao funcionaria colocar um 'pub export const' para cada um
    // la na proprio config, ja que pode acontecer de alguma nao ser usada diretamente no codigo, mas ser
    // usada dentro de um linker ou assembly, isso iria dar um erro de simbolo nao encontrado, ja que como
    // nao foi usada dentro do proprio codigo zig, o compilador so iria ignorar e nem colocar o export nela
    const aux: type = opaque {
        pub fn make_asm_set(comptime name: []const u8, comptime value: u32) []const u8 {
            return ".set " ++ name ++ ", " ++ lib.utils.fmt.intFromArray(value) ++ "\n"
                ++ ".globl " ++ name ++ "\n"
            ;
        }
    };
    // caso a arquitetura nao use uma configuracao default, fica por conta dela mesmo fazer isso
    if(@field(code.arch, decls.what_is_decl(.arch)).symbols.segments == 1 ) asm(
        aux.make_asm_set("kernel_phys_address", config.kernel.mem.phys.kernel_phys) ++
        aux.make_asm_set("kernel_virtual_address", config.kernel.mem.virtual.kernel_text) ++
        aux.make_asm_set("kernel_text_virtual", config.kernel.mem.virtual.kernel_text) ++
        aux.make_asm_set("kernel_stack_base_virtual", config.kernel.mem.virtual.kernel_stack_base) ++
        aux.make_asm_set("kernel_data_virtual", config.kernel.mem.virtual.kernel_data) ++
        aux.make_asm_set("kernel_paged_memory_virtual", config.kernel.mem.virtual.kernel_paged_memory) ++
        aux.make_asm_set("kernel_mmio_virtual", config.kernel.mem.virtual.kernel_mmio)
    );
}

pub fn saturn_arch_verify() void {
    const aux: type = opaque {
        pub fn export_this(
            comptime ptr: *const anyopaque,
            comptime label: []const u8,
            comptime section: ?[]const u8
        ) void {
            @export(ptr, .{
                .name = label,
                .section = section,
            });
        }
    };
    const decl = decls.saturn_especial_decls[
        @intFromEnum(decls.DeclsOffset_T.arch)
    ];
    if(!@hasDecl(arch, decl)) {
        @compileError(
            "expected a declaration " ++ decl ++ " for architecture " ++
            @tagName(config.arch.options.Target)
        );
    }
    const decl_type = @TypeOf(arch.__SaturnArchDescription__);
    const decl_expect_type = decls.saturn_especial_decls_types[
        @intFromEnum(decls.DeclsOffset_T.arch)
    ];
    if(decl_type != decl_expect_type) {
        @compileError(
            "declaration " ++ decl ++ " for architecture " ++
            @tagName(config.arch.options.Target) ++
            " must be type: " ++
            @typeName(decls.saturn_especial_decls_types[
                @intFromEnum(decls.DeclsOffset_T.arch)
            ])
        );
    }
    if(!arch.__SaturnArchDescription__.usable) {
        @compileError(
            "target kernel cpu architecture " ++
            @tagName(config.arch.options.Target) ++
            " has no guarantee of functioning by the developer"
        );
    }
    const arch_fields = @typeInfo(decl_expect_type).@"struct".fields;
    for(arch_fields) |field| {
         // ignore usable field
        if(field.type == bool) continue;
        const opt: bool = sw: switch(@typeInfo(field.type)) {
            .optional => {
                if(@field(arch.__SaturnArchDescription__, field.name) == null) continue;
                if(field.type == ?[]const decl_expect_type.Extra_T) {
                    for((@field(arch.__SaturnArchDescription__, field.name)).?) |extra| {
                        const union_field = switch(extra.entry) {
                            .c => |c| c,
                            .naked => |naked| naked,
                        };
                        aux.export_this(union_field, extra.label, null);
                    }
                    continue;
                }
                if(field.type == ?[]const decl_expect_type.Data_T) {
                    for((@field(arch.__SaturnArchDescription__, field.name)).?) |data| {
                        aux.export_this(data.ptr, data.label, null);
                    }
                    continue;
                }
                break :sw true;
            },
            else => {
                switch(field.type) {
                     decl_expect_type.Overrider_T,
                     decl_expect_type.Symbols_T => continue,
                     else => break :sw false,
                }
            }
        };
        aux.export_this(
            if(opt) (@field(arch.__SaturnArchDescription__, field.name)).?.entry else
                (@field(arch.__SaturnArchDescription__, field.name)).entry,
            if(opt) (@field(arch.__SaturnArchDescription__, field.name)).?.label else
                (@field(arch.__SaturnArchDescription__, field.name)).label,
            null
        );
    }
}

pub fn saturn_running() noreturn {
    while(true) {}
}
