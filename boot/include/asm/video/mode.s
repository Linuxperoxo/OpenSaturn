#    /--------------------------------------------O
#    |                                            |
#    |  COPYRIGHT : (c) 2025 per Linuxperoxo.     |
#    |  AUTHOR    : Linuxperoxo                   |
#    |  FILE      : mode.s                        |
#    |                                            |
#    O--------------------------------------------/

.ifndef MODE
.equ MODE, 0

.weak VBE_DEFAULT_MODE # NOTE: Definimos como fraco, assim podemos mudar em qualquer outro lugar
.equ VBE_DEFAULT_MODE, 0x117

.section .atlas.text.mode, "ax", @progbits
.code16
.global GetMode
.align 4
.type GetMode, @function
GetMode:
  # NOTE: Parameter:
  #         * %bx -> Mode
  #         * %di -> Struct ptr
 
  pushw %ax
  pushw %cx

  movw $VBE_DEFAULT_MODE, %ax
  
  # NOTE: Pegando as informações do modo VBE, caso %bx for 0 pegamos o modo default
  testw   %bx, %bx
  cmovnzw %bx, %cx
  cmovzw  %ax, %cx

  movw $0x4F01, %ax
  int  $0x10

  popw %cx
  popw %ax
  ret

.global SetMode
.align 4
.type SetMode, @function
SetMode:

  # NOTE: Parameter:
  #         * %bx -> Mode

  pushw %cx
  pushw %di
  pushw %bp

  movw $VBE_DEFAULT_MODE, %cx
  
  testw  %bx, %bx
  cmovzw %cx, %bx

  # NOTE: Habilitando modo 0x117 e limpando a memoria de vídeo
  andw $0x0FFF, %bx 
  orw  $0x4000, %bx
  movw $0x4F02, %ax
  int  $0x10

  popw %bp
  popw %di
  popw %cx
  ret
.else
  .warning "asm/video/mode.s is already defined!"
.endif
