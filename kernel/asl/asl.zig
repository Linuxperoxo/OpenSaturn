// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: asl.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Arch Static Loader

const code: type = @import("root").code;
const decls: type = @import("root").decls;
const config: type = @import("root").config;
const aux: type = @import("aux.zig");

comptime {
    if(!@hasDecl(code.arch, decls.what_is_decl(.arch))) @compileError(
        "expected a declaration " ++ decls.what_is_decl(.arch) ++ " for architecture " ++
        @tagName(config.arch.options.Target)
    );

    if(@TypeOf(decls.decl_access(code.arch, .arch)) != decls.what_is_decl_type(.arch)) @compileError(
        "declaration \"" ++ decls.what_is_decl(.arch) ++ "\" for architecture \"" ++ @tagName(config.arch.options.Target) ++ "\" must be type \"" ++
        @typeName(decls.what_is_decl_type(.arch)) ++ "\""
    );

    // NOTE: usar assembly inline dentro do nucleo de um kernel e totalmente desencorajado, ja
    // que aquele codigo so funciona apenas para uma arquitetura, ou seja, vamos precisar
    // ter um codigo assembly naquela parte para cada arquitetura, nesse caso, nao tem problema
    // nenhum em usar assembly inline aqui, ja que usamos diretivas, nao instrucoes, isso funciona
    // para assembly de qualquer arquitetura suportada pelo GAS

    // isso aqui realmente precisa ser feito, nao funcionaria colocar um 'pub export const' para cada um
    // la na proprio config, ja que pode acontecer de alguma nao ser usada diretamente no codigo, mas ser
    // usada dentro de um linker ou assembly, isso iria dar um erro de simbolo nao encontrado, ja que como
    // nao foi usada dentro do proprio codigo zig, o compilador so iria ignorar e nem colocar o export nela
    if(@field(code.arch, decls.what_is_decl(.arch)).symbols.segments == 1 ) asm(
        aux.asm_set("kernel_phys_address", config.kernel.mem.phys.kernel_phys) ++
        aux.asm_set("kernel_virtual_address", config.kernel.mem.virtual.kernel_text) ++
        aux.asm_set("kernel_text_virtual", config.kernel.mem.virtual.kernel_text) ++
        aux.asm_set("kernel_stack_base_virtual", config.kernel.mem.virtual.kernel_stack_base) ++
        aux.asm_set("kernel_data_virtual", config.kernel.mem.virtual.kernel_data) ++
        aux.asm_set("kernel_paged_memory_virtual", config.kernel.mem.virtual.kernel_paged_memory) ++
        aux.asm_set("kernel_mmio_virtual", config.kernel.mem.virtual.kernel_mmio)
    );

    const arch_decl_type: type = decls.what_is_decl_type(.arch);
    const arch_decl = decls.decl_access(code.arch, .arch);

    for(@typeInfo(arch_decl_type).@"struct".fields) |field| {
        const current_field = @field(arch_decl, field.name);
        const current_field_type = @TypeOf(current_field);

        sw: switch(@typeInfo(current_field_type)) {
            .optional => |opt| continue :sw @typeInfo(
                if(current_field != null) opt.child else void
            ),

            .pointer => |ptr| {
                switch(ptr.child) {
                    arch_decl_type.Extra_T => {
                        for(current_field.?) |extra| {
                            @export(extra.entry.actived_field(), .{
                                .name = extra.label
                            });
                        }
                    },

                    arch_decl_type.Data_T => {
                        for(current_field.?) |data| {
                            @export(data.ptr, .{
                                .name = data.label,
                                .section = data.section,
                            });
                        }
                    },

                    else => unreachable,
                }
            },

            .@"struct" => {
                const struct_type: type = aux.extract_opt_child(@TypeOf(current_field));
                if(!@hasField(struct_type, "label") or !@hasField(struct_type, "entry")) break :sw {};
                @export(aux.ret_export_entry(arch_decl, field.name), .{
                    .name = aux.ret_export_label(arch_decl, field.name),
                });
            },

            else => break :sw {},
        }
    }
}
