// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: entry.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").arch;
const config: type = @import("root").config;

const arch_section_text_loader = arch.arch_section_text_loader;
const arch_section_data_loader = arch.arch_section_data_loader;

// callconv(.naked) não tem prólogo e epílogo automáticos é simplesmente fazer uma função do 0,
// o compilador não adiciona o código de prólogo/epílogo para salvar/restaurar registradores ou
// manipular a pilha, como alocações e desalocação.
//
// linksection(".text.saturn.entry") serve para por essa label em uma section explícita, poderiamos
// usar o @export para isso
//
// export serve para deixar o símbolo vísivel no assembly, ou seja, poderiamos usar o asm volatile(\\call Sentry);
// em qualquer arquivo, já que o símbolo está vísivel em todo o assembly.

// FIXME: tirar o linksection, atualmente o codigo so funciona com o
// linksection, por  algum motivo mesmo usando o @export la no loader
// o codigo do init nao esta sendo carregado na section correta
pub fn entry() linksection(arch_section_text_loader) callconv(.naked) noreturn {
    asm volatile(
        \\ cli
        \\ movl %[phys_stack], %esp
        \\ call .x86.init
        // \\ call .x86.interrupts
        \\ call .x86.mm
        \\ jmp .
        \\ call saturn.main
        \\ jmp .
        :
        :[phys_stack] "i" (
            comptime (config.kernel.options.kernel_stack_base_phys_address + config.kernel.options.kernel_stack_size)
        )
    );

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
    asm volatile(
        \\  .equ AtlasMagic, 0xAB00
        \\  .equ AtlasLoadDest, 0x1000000
        \\  .weak AtlasImgSize
        \\  .equ AtlasVMode, 0x1000
        \\  .equ AtlasFlags, 0b00000001
        \\  .section .opensaturn.data.atlas.header,"a",@progbits
        \\  .type AtlasHeaders,@object
        \\ AtlasHeaders:
        \\   .word AtlasMagic
        \\   .long AtlasLoadDest
        \\   .long .x86.entry - AtlasLoadDest
        \\   .long AtlasImgSize
        \\   .word AtlasVMode
        \\   .byte AtlasFlags
    );
}

