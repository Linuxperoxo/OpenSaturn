#    /--------------------------------------------O
#    |                                            |
#    |  COPYRIGHT : (c) 2025 per Linuxperoxo.     |
#    |  AUTHOR    : Linuxperoxo                   |
#    |  FILE      : entry.s                       |
#    |                                            |
#    O--------------------------------------------/

.equ ATLASMAGIC, 0xAB00
.equ ATLASLOAD, 0x1000000
.equ STACK, 0x3000000

.extern Smain

.section .opensaturn.text.entry, "ax", @progbits
.code32
.align 4
.type Sentry, @function
Sentry:
  cli
  movl $STACK, %esp
  call Smain
  hlt

.section .opensaturn.atlas.entry, "a", @progbits
.type .AtlasFlags, @object
.AtlasFlags:               # NOTE: Esse headers deve ser colocado no início do binário
  .word ATLASMAGIC         # NOTE: Flag mágica para dizer para o Atlas que é um arquivo válido para boot
  .long ATLASLOAD          # NOTE: Endereço de memória físico de onde o arquivo deve ser carregado 
  .long Sentry - ATLASLOAD # NOTE: Offset dentro do arquivo para o onde o Atlas deve passar o controle de execução.
  .long ATLASSIZE          # NOTE: Tamanho do arquivo em bytes, esse está sendo colocado diretamente no ../linker.ld

