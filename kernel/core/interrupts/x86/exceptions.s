  .macro exception int
      .code32
      .globl exception\int
      .align 4
      .type exception,@function
    exception\int:
      pushl $\int
      jmp exception_handler
  .endm

  .section opensaturn.text.cpu.exceptions,"ax",@progbits
  .code32
  .globl exception_handler
  .align 4
  .type exception_handler,@function
exception_handler:
  jmp .

exception 0
exception 1
exception 2
exception 3
exception 4
exception 5
exception 6
exception 7
exception 8
exception 9
exception 10
exception 11
exception 12
exception 13
exception 14
exception 15
exception 16
exception 17
exception 18
exception 19
exception 20
exception 21
exception 22
exception 23
exception 24
exception 25
exception 26
exception 27
exception 28
exception 29
exception 30
exception 31
