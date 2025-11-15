#    /--------------------------------------------O
#    |                                            |
#    |  COPYRIGHT : (c) 2025 per Linuxperoxo.     |
#    |  AUTHOR    : Linuxperoxo                   |
#    |  FILE      : ata.s                         |
#    |                                            |
#    O--------------------------------------------/

.ifndef ATA
.equ ATA, 0
  .equ DATA_PORT, 0x1F0 # Porta de dados
  .equ ERROR_PORT, 0x1F1 # Porta de erro
  .equ SECTOR_COUNT, 0x1F2 # Número de setores
  .equ SECTOR_NUMBER, 0x1F3 # Número do setor | LBA low
  .equ CYLINDER_LOW, 0x1F4 # Cilindro (bits baixos) | LBA mid
  .equ CYLINDER_HIGH, 0x1F5 # Cilindro (bits altos) | LBA high
  .equ LBA_LOW, 0x1F3 # LBA low
  .equ LBA_MID, 0x1F4 # LBA mid
  .equ LBA_HIGH, 0x1F5 # LBA high
  .equ DRIVE_HEAD, 0x1F6 # Seleção de drive e Cabeçote
  .equ STATUS_PORT, 0x1F7 # Porta de status
  .equ COMMAND_PORT, 0x1F7 # Porta de comando
  .equ COMMAND_READ, 0x20 # Comando de leitura para a porta 0x1F7
  .equ SECTOR_SIZE_BYTE, 512 # Tamanho de cada setor em bytes
  .equ SECTOR_SIZE_WORD, 256 # Tamanho de cada setor em words

  .section .atlas.text.ata, "ax", @progbits
  .code32
  .global ataLBA_R
  .align 4
  .type ataLBA_R, @function
  ataLBA_R:

    # NOTE:
    # -   (%ebp): u8 __head__;
    # -  4(%ebp): u8 __sectors_to_read__;
    # -  8(%ebp): u32 __drive_addrs__;
    # - 12(%ebp): u32 __dest_addrs__;
 
    # NOTE:
    # Para fazer a manipulação do disco usando o controlador ATA
    # precisamos usar instruções OUT e IN de 8 bits, também precisamos
    # mandar os comandos para as portas corretas

    pushl %ebp

    leal 8(%esp), %ebp

    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx
    pushl %edi

    # NOTE:
    # Porta 0x1F7:
    #   (Bits 0-3): Cabeçote
    #   (Bit 4): Drive | 0 -> Master | 1 -> Slave. OBS: ATA só suporta 2 drive, o master e o slave
    #   (Bit 5): Nos primeiros padrões de discos rígidos (IDE/ATA antigos), esse bit tinha uma função específica. No entanto, com a evolução do protocolo, ele foi fixado em 1 para manter compatibilidade.
    #   (Bit 6): Tipo de endereçamento, 0 -> CHS | 1 -> LBA
    #   (Bit 7): Esse bit sempre deve ser 1 de acordo com a especificação ATA.
    movb (%ebp),      %al
    andb $0x0F,       %al
    orb  $0b11100000, %al
    movw $DRIVE_HEAD, %dx
    outb %al,         %dx

    # NOTE:
    # Porta 0x1F2:
    #   Configurando a quantidade de setores para leitura
    movb 4(%ebp),       %al
    movw $SECTOR_COUNT, %dx
    outb %al,           %dx

    # NOTE:
    # Porta 0x1F3:
    #   Configurando o endereço LBA low
    movl 8(%ebp),  %eax
    movw $LBA_LOW, %dx
    outb %al,      %dx

    # NOTE:
    # Porta 0x1F4:
    #   Configurando o endereço LBA mid
    shrl $8, %eax
    incw %dx
    outb %al, %dx

    # NOTE:
    # Porta 0x1F5:
    #   Configurando o endereço LBA high
    shrl $8, %eax
    incw %dx
    outb %al, %dx

    # NOTE:
    # Porta 0x1F7:
    #   Enviando comando de leitura para o controlador ATA
    movb $COMMAND_READ, %al
    movw $COMMAND_PORT, %dx
    outb %al, %dx

    movw  $ERROR_PORT, %dx
    inb   %dx,         %al
    testb %al,         %al
    jnz   1f
    jmp   2f

    1:
      #movl $1, %eax # NOTE: Erro na leitura
      jmp .

    2:
      xorl %ebx, %ebx
      movw 4(%ebp),  %bx  # NOTE: Setores a serem lidos
      movl 12(%ebp), %edi # NOTE: Endereço de destino dos dados lidos
      cld

    1:
      testl %ebx, %ebx
      jz    3f
      decl  %ebx
      movw  $STATUS_PORT, %dx

    2:
      inb   %dx, %al
      testb $0x08, %al # NOTE: Vendo se o bit de DATA READY está levantado
      jz    2b         # NOTE: Caso não esteja, vamos continua esperando

      movl $SECTOR_SIZE_WORD, %ecx
      movw $DATA_PORT,        %dx

      # NOTE:
      # REP: Repete uma instrução até %ecx != 0. OBS: A cada interação %ecx será decrementado
      # INSW: Lê a porta de %dx, e manda os dados para %es:%di. Se DF = 0 (CLD), 
      #       %di será somado pelo tamanho da operação(insb = %di + 1, insw %di + 2, insl % di + 4) 
      #       cada vez que executar essa intrução, caso DF = 1 (STD), %di será subtraido pelo tamanho da operação
      rep insw
      jmp 1b

    # TODO: Fazer um retorno de status pelo %eax

    3:
      popl %edi
      popl %edx
      popl %ecx
      popl %ebx
      popl %eax
      popl %ebp
      ret

  .global ataLBA_W
  .align 4
  .type ataLBA_W, @function
  ataLBA_W:
.else
  .warning "asm/io/ata.s is already defined!"
.endif
