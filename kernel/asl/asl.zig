// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: asl.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Architecture Signature & Linker

// o architecture signature & linker é o mecanismo do OpenSaturn
// responsável por verificar a assinatura da arquitetura e carregar
// os detalhes específicos da arquitetura no kernel. É nesse ponto
// que o código da arquitetura é validado e integrado ao kernel.

const arch_impl = @import("root").__SaturnArchImpl__;

const decls: type = @import("root").decls;
const config: type = @import("root").config;
const fmt: type = @import("root").lib.kernel.meta.fmt;
const aux: type = @import("aux.zig");

comptime {
    if(!@hasDecl(arch_impl.arch, decls.whatIsDecl(.arch))) @compileError(
        "expected a declaration " ++ decls.whatIsDecl(.arch) ++ " for architecture " ++
        @tagName(config.arch.options.target)
    );

    if(@TypeOf(decls.declAccess(arch_impl.arch, .arch)) != decls.whatIsDeclType(.arch)) @compileError(
        "declaration \"" ++ decls.whatIsDecl(.arch) ++ "\" for architecture \"" ++ @tagName(config.arch.options.target) ++ "\" must be type \"" ++
        @typeName(decls.whatIsDeclType(.arch)) ++ "\""
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
    if(@field(arch_impl.arch, decls.whatIsDecl(.arch)).symbols.segments == 1 ) asm(
        &fmt.format(".set {s}, {d}\n", .{ "kernel_phys_address", config.kernel.mem.phys.kernel_phys }) ++
        &fmt.format(".global {s}\n", .{ "kernel_phys_address" }) ++
        &fmt.format(".set {s}, {d}\n", .{ "kernel_virtual_address", config.kernel.mem.virtual.kernel_text }) ++
        &fmt.format(".global {s}\n", .{ "kernel_virtual_address" }) ++
        &fmt.format(".set {s}, {d}\n", .{ "kernel_text_virtual", config.kernel.mem.virtual.kernel_text }) ++
        &fmt.format(".global {s}\n", .{ "kernel_text_virtual" }) ++
        &fmt.format(".set {s}, {d}\n", .{ "kernel_stack_base_virtual", config.kernel.mem.virtual.kernel_stack_base }) ++
        &fmt.format(".global {s}\n", .{ "kernel_stack_base_virtual" }) ++
        &fmt.format(".set {s}, {d}\n", .{ "kernel_data_virtual", config.kernel.mem.virtual.kernel_data }) ++
        &fmt.format(".global {s}\n", .{ "kernel_data_virtual" }) ++
        &fmt.format(".set {s}, {d}\n", .{ "kernel_paged_memory_virtual", config.kernel.mem.virtual.kernel_paged_memory }) ++
        &fmt.format(".global {s}\n", .{ "kernel_paged_memory_virtual" }) ++
        &fmt.format(".set {s}, {d}\n", .{ "kernel_mmio_virtual", config.kernel.mem.virtual.kernel_mmio }) ++
        &fmt.format(".global {s}\n", .{ "kernel_mmio_virtual" })
    );

    const arch_decl_type: type = decls.whatIsDeclType(.arch);
    const arch_decl = decls.declAccess(arch_impl.arch, .arch);

    for(@typeInfo(arch_decl_type).@"struct".fields) |field| {
        const current_field = @field(arch_decl, field.name);
        const current_field_type = @TypeOf(current_field);

        sw: switch(@typeInfo(current_field_type)) {
            .optional => |opt| continue :sw @typeInfo(
                if(current_field != null) opt.child else void
            ),

            .pointer => |ptr| {
                switch(ptr.child) {
                    arch_decl_type.Extra => {
                        for(current_field.?) |extra| {
                            @export(extra.entry.activedField(), .{
                                .name = extra.label
                            });
                        }
                    },

                    arch_decl_type.Data => {
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
                const struct_type: type = aux.extractOptChild(@TypeOf(current_field));
                if(!@hasField(struct_type, "label") or !@hasField(struct_type, "entry")) break :sw {};
                @export(aux.retExportEntry(arch_decl, field.name), .{
                    .name = aux.retExportLabel(arch_decl, field.name),
                });
            },

            else => break :sw {},
        }
    }
}
