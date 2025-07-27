// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: idt.zig        │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const idtEntry_T: type = packed struct {
    low: u16, // Parte baixa do endereço ISR (Interrupt Service Routine)
    segment: u16, // Aponta para o seletor de segmento usado para acessar o codigo do ISR
    always0: u8, // Sempre 0
    flags: u8, // Inclui o tipo de interrupçao (hardware/software), nivel de previlegio (DPL) e a presença da interrupçao (bit P)
    // * bit 7   - Present Bit
    // * bit 6-5 - DPL
    // * bit 4   - Sempre 0
    // * bit 3-0 - Gate Type
    high: u16, // Parte alta do endereço do ISR
};

// Gate Types:
// Interrupt Gate(0b1110): Mascara interrupções, não permite interrupção dentro de interrupção
// Trap Gate(0b1111): Não Mascara interrupções, permite interrupão dentro de interrupção
// Task Gate(0b0101): CPU Troca para uma task diferente (Task State Segment)

pub const lidt_T: type = packed struct {
    limit: u16, // Offset maximo de entradas em bytes
    entries: [*]idtEntry_T, // Endereço para as entradas IDT
};

// Exceção 0 - Division By Zero:
// Ocorre quando o processador tenta dividir um número por zero.
//
// Exceção 1 - Debug:
// Usada pelo depurador, é gerada quando uma instrução de depuração é encontrada, como o comando `int 3`.
//
// Exceção 2 - Non Maskable Interrupt (NMI):
// Uma interrupção crítica que não pode ser mascarada. Frequentemente associada a falhas de hardware, como memória defeituosa.
//
// Exceção 3 - Breakpoint:
// Gerada quando o processador encontra uma instrução de breakpoint (normalmente `int 3`), usada para depuração.
//
// Exceção 4 - Into Detected Overflow (Overflow):
// Ocorre quando uma operação aritmética resulta em um overflow, ou seja, o valor excede o limite que pode ser representado no tipo de dado.
//
// Exceção 5 - Bound Range Exceeded:
// Gerada quando o processador detecta um erro no uso da instrução `BOUND`, que verifica se um índice está dentro de um intervalo especificado.
//
// Exceção 6 - Invalid Opcode:
// Ocorre quando o processador encontra um opcode (código de operação) inválido ou desconhecido.
//
// Exceção 7 - No Coprocessor:
// Gerada quando uma instrução que requer um coprocessador (como a FPU) é executada, mas o coprocessador não está presente.
//
// Exceção 8 - Double Fault:
// Ocorre quando uma exceção é gerada enquanto o processador ainda está lidando com outra exceção.
// 
// Exceção 9 - Coprocessor Segment Overrun:
// Relacionada a um erro de acesso ao coprocessador, como um erro ao acessar o segmento de dados do coprocessador.
//
// Exceção 10 - Invalid TSS (Task State Segment):
// Gerada quando o processador encontra um erro ao acessar o Task State Segment (TSS), que mantém o estado de uma tarefa no sistema.
//
// Exceção 11 - Stack Fault:
// Ocorre quando há um erro relacionado à pilha, como um estouro de pilha ou uma violação de acesso.
//
// Exceção 12 - Page Fault:
// Ocorre quando o processador tenta acessar uma página de memória que não está mapeada ou que está fora dos limites da memória física.
//
// Exceção 13 - General Protection Fault:
// Gerada quando o processador detecta uma violação de proteção de memória, como acessar uma área de memória protegida ou executar uma operação inválida.
//
// Exceção 14 - Unknown Interrupt:
// Uma interrupção desconhecida ou não mapeada. Ocorre quando o processador recebe uma interrupção inválida.
//
// Exceção 15 - Coprocessor Fault:
// Gerada quando ocorre uma falha ao tentar acessar ou utilizar um coprocessador.
//
// Exceção 16 - Machine Check Exception:
// Indica uma falha crítica de hardware, como falhas de memória ou falhas no próprio processador.
//
// Exceções 17 a 31 - None:
// Essas exceções não são usadas pela arquitetura x86 e são reservadas para uso futuro ou personalização. Elas podem ser usadas em implementações específicas ou em extensões do processador.

pub const cpuExceptionsMessagens = [_][]const u8{
  "Division By Zero",               // Exceção 0  - Division By Zero
  "Debug",                          // Exceção 1  - Debug
  "Non Maskable Interrupt",         // Exceção 2  - Non Maskable Interrupt (NMI)
  "Breakpoint",                     // Exceção 3  - Breakpoint
  "Into Detected Overflow",         // Exceção 4  - Into Detected Overflow (Overflow)
  "Out of Bounds",                  // Exceção 5  - Bound Range Exceeded
  "Invalid Opcode",                 // Exceção 6  - Invalid Opcode
  "No Coprocessor",                 // Exceção 7  - No Coprocessor (Coprocessor Not Available)
  "Double fault",                   // Exceção 8  - Double Fault
  "Coprocessor Segment Overrun",    // Exceção 9  - Coprocessor Segment Overrun
  "Bad TSS",                        // Exceção 10 - Invalid TSS (Task State Segment)
  "Stack Fault",                    // Exceção 11 - Stack Fault
  "Page Fault",                     // Exceção 12 - Page Fault
  "General Protection Fault",       // Exceção 13 - General Protection Fault
  "Unknown Interruption",           // Exceção 14 - Unknown Interrupt
  "Coprocessor Fault",              // Exceção 15 - Coprocessor Fault
  "Machine Check",                  // Exceção 16 - Machine Check Exception
  "None",                           // Exceção 17 - None
  "None",                           // Exceção 18 - None
  "None",                           // Exceção 19 - None
  "None",                           // Exceção 20 - None
  "None",                           // Exceção 21 - None
  "None",                           // Exceção 22 - None
  "None",                           // Exceção 23 - None
  "None",                           // Exceção 24 - None
  "None",                           // Exceção 25 - None
  "None",                           // Exceção 26 - None
  "None",                           // Exceção 27 - None
  "None",                           // Exceção 28 - None
  "None",                           // Exceção 29 - None
  "None",                           // Exceção 30 - None
  "None"                            // Exceção 31 - None
};
