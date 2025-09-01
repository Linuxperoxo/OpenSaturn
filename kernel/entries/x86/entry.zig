// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: entry.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const entry_T: type = @import("root").interfaces.arch.entry_T;

pub const __SaturnEntryDescription__: entry_T = .{
    .maintainer = "Linuxperoxo",
    .entry = &entry,
    .label = "x86_entry",
    .section = ".text.entry",
};

// callconv(.naked) não tem prólogo e epílogo automáticos é simplesmente fazer uma função do 0,
// o compilador não adiciona o código de prólogo/epílogo para salvar/restaurar registradores ou
// manipular a pilha, como alocações e desalocação.
//
// linksection(".text.saturn.entry") serve para por essa label em uma section explícita, poderiamos
// usar o @export para isso
//
// export serve para deixar o símbolo vísivel no assembly, ou seja, poderiamos usar o asm volatile(\\call Sentry);
// em qualquer arquivo, já que o símbolo está vísivel em todo o assembly.
fn entry() callconv(.naked) noreturn {
    asm volatile(
        \\ cli
        \\ movl $0xF00000, %esp
        \\ call saturn.main
        \\ jmp .
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
        \\   .long x86_entry - AtlasLoadDest
        \\   .long AtlasImgSize
        \\   .word AtlasVMode
        \\   .byte AtlasFlags
    );
}

