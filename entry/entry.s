#    /--------------------------------------------O
#    |                                            |
#    |  COPYRIGHT : (c) 2025 per Linuxperoxo.     |
#    |  AUTHOR    : Linuxperoxo                   |
#    |  FILE      : entry.s                       |
#    |                                            |
#    O--------------------------------------------/

.equ AtlasMagic, 0xAB00
.equ AtlasLoadDest, 0x1000000
.equ AtlasVMode, 0x1000
.equ AtlasFlags, 0b00000001

.equ STACK, 0x3000000

.extern smain

.section .opensaturn.text.entry, "ax", @progbits
.code32
.align 4
.type Sentry, @function
Sentry:
  cli
  movl $STACK, %esp
  pushl %eax # NOTE: Passando o ponteiro da struct VBE Mode para Smain
  call smain
  hlt

.section .opensaturn.atlas.entry, "a", @progbits
.type .AtlasFlags, @object
.AtlasFlags:                   # NOTE: Esse headers deve ser colocado no início do binário
  .word AtlasMagic             # NOTE: Flag mágica para dizer para o Atlas que é uma imagem válida para boot
  .long AtlasLoadDest          # NOTE: Endereço de memória físico de onde a imagem deve ser carregado 
  .long Sentry - AtlasLoadDest # NOTE: Offset dentro do arquivo para o onde o Atlas deve passar o controle de execução.
  .long AtlasImgSize           # NOTE: Tamanho do arquivo em bytes, esse está sendo colocado diretamente no ../linker.ld
  .word AtlasVMode             # NOTE: Modo de vídeo que queremos, VGA 80x25
  .byte AtlasFlags             # NOTE: Flags gerais para o Atlas, consulte a documentação no código do Atlas https://github.com/Linuxperoxo/AtlasB/blob/master/src/atlas.s
