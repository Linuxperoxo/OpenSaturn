#    /--------------------------------------------O
#    |                                            |
#    |  COPYRIGHT : (c) 2025 per Linuxperoxo.     |
#    |  AUTHOR    : Linuxperoxo                   |
#    |  FILE      : gdt.s                         |
#    |                                            |
#    O--------------------------------------------/

.ifndef GDT
.equ GDT, 0

.section .atlas.data.gdt, "aw", @progbits
.type .GDTS, @object
.GDTS:
  .long 0x00000000
  .long 0x00000000

  .word 0xFFFF
  .word 0x0000
  .byte 0x00
  .byte 0b10011010
  .byte 0b11001111
  .byte 0x00

  .word 0xFFFF
  .word 0x0000
  .byte 0x00
  .byte 0b10010010
  .byte 0b11001111
  .byte 0x00
.GDTE:

.global GDTP
.type GDTP, @object
GDTP:
  .word .GDTE - .GDTS
  .long .GDTS
.else
  .warning "asm/cpu/gdt.s is already defined!"
.endif
