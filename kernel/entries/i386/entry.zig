// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: entry.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("root").config;
const kernel: type = @import("root").kernel;
const atlas: type = @import("atlas.zig");

const section_text_loader = arch.sections.section_text_loader;
const section_data_loader = arch.sections.section_data_loader;
const section_data_persist = arch.sections.section_data_persist;

// callconv(.naked) não tem prólogo e epílogo automáticos é simplesmente fazer uma função do 0,
// o compilador não adiciona o código de prólogo/epílogo para salvar/restaurar registradores ou
// manipular a pilha, como alocações e desalocação.
//
// linksection(".text.saturn.entry") serve para por essa label em uma section explícita, poderiamos
// usar o @export para isso
//
// export serve para deixar o símbolo vísivel no assembly, ou seja, poderiamos usar o asm volatile(\\call Sentry);
// em qualquer arquivo, já que o símbolo está vísivel em todo o assembly.

comptime {
    const aux: type = opaque {
        pub fn make_asm_set(comptime name: []const u8, comptime value: u32) []const u8 {
            return ".set " ++ name ++ ", " ++ kernel.utils.fmt.intFromArray(value) ++ "\n";
        }
    };
    // AtlasB Headers
    //
    // Esse Headers deve ser colocado no inicio do binario, em
    // seus primeiros 17 bytes.
    //
    // * AtlasMagic: Numero magico que fala para o Atlas que e uma imagem valida
    // * AtlasLoadDest: Endereço de memoria fisico onde o binario vai ser carregado
    // * Offset dentro do arquivo onde fica o entry do codigo, o atlas vai dar jump nesse offset
    // * AtlasImgSize: Tamanho total do binario em bytes
    // * AtlasVMode: Modo de video que deve ser colocado
    // * AtlasFlags: Flags gerais para o Atlas, consulte a documentaçao no fonte do atlas
    //    NOTE: https://github.com/Linuxperoxo/AtlasB/blob/master/src/atlas.s
    asm(
        aux.make_asm_set("AtlasLoadDest", atlas.atlas_load_dest) ++
        aux.make_asm_set("AtlasVMode", atlas.atlas_vmode) ++
        aux.make_asm_set("AtlasFlags", atlas.atlas_flags) ++
        \\  .set AtlasMagic, 0xAB00
        \\  .weak AtlasImgSize
        \\  .section .opensaturn.data.atlas.header,"a",@progbits
        \\  .type AtlasHeaders,@object
        \\ AtlasHeaders:
        \\   .word AtlasMagic
        \\   .long AtlasLoadDest
        \\   .long .i386.entry - AtlasLoadDest
        \\   .long AtlasImgSize
        \\   .word AtlasVMode
        \\   .byte AtlasFlags
    );
}

pub fn entry() linksection(section_text_loader) callconv(.naked) noreturn {
    asm volatile(
        \\ cli
        \\ movl %[phys_stack], %esp
        \\ calll .i386.init
        \\ calll .i386.mm
        \\ calll .i386.gdt
        \\ calll .i386.interrupts
        \\ calll .i386.idt.csi
        \\ calll .i386.physio
        \\ jmp saturn.main
        :
        :[phys_stack] "i" (
            comptime (config.kernel.mem.phys.kernel_stack_base + config.kernel.options.kernel_stack_size)
        ),
         [_] "{edi}" (
            arch.linker.phys_address_opensaturn_data_start
        )
    );
}

