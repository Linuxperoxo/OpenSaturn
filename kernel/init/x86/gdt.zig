// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: gdt.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === COMO FUNCIONAM OS REGISTRADORES DE SEGMENTO? ===
//
// No modo protegido, os registradores de segmento (DS, SS, CS, etc.)
// possuem 16 bits e seguem uma estrutura específica.
//
// Vamos usar o registrador CS (Code Segment) como exemplo:
//
//     7654 3210
// CS: 0000 1000   // Valor em binário
//     0x08        // Representação em hexadecimal
//
// Estrutura dos bits:
//
// Bits 0-1: RPL - Request Privilege Level
//     - Indica o nível de privilégio (0 a 3)
//     - 0 = nível mais alto de privilégio
//
// Bit 2: TI - Table Indicator
//     - 0 = Segmento está na GDT (Global Descriptor Table)
//     - 1 = Segmento está na LDT (Local Descriptor Table)
//
// Bits 3-15: SI - Segment Index
//     - Representa o índice da entrada na GDT ou LD
//     - No valor 0x08 (0000 1000), índice = 1 (começa do 0)
//
// Resumo para 0x08:
//     RPL: 00  -> Privilégio 0
//     TI:  0   -> Usando a GDT
//     SI:  00001 -> Entrada 1 na GDT
//

// === ESTRUTURA GDTPointer ===
//
// Esta estrutura representa o ponteiro para a Tabela Global de Descritores (GDT),
// que deve ser carregado com a instrução lgdt no modo protegido.
//
// Estrutura esperada pela CPU (formato definido pela arquitetura x86):
//
//  Campo      | Descrição
// ------------|-------------------------------------------
//  Limit (u16)| Tamanho total da GDT - 1
//  First (u32)| Endereço base da GDT
//
// - Limit: Tamanho (em bytes) da tabela GDT menos 1.  
//          Isso é necessário porque o valor armazenado representa o maior offset válido.
//
// - First: Endereço onde a GDT está localizada na memória.  
//          Deve ser um ponteiro para a primeira entrada válida da GDT.
//
// Essa estrutura deve estar alinhada e empacotada corretamente para ser aceita
// pela instrução lgdt, que exige exatamente 6 bytes:
//     2 bytes para o limite + 4 bytes para o endereço base.
//
// Exemplo de uso com assembly inline:
//     asm volatile ("lgdt [%0]" :: "r" (&GDTPointer) : "memory");
//
//
var GDTPointer: packed struct {
    Limit: u16 = 0,
    First: u32 = 0,
} = undefined;

// === ESTRUTURA GDTEntry ===
//
// Representa uma entrada na GDT (Global Descriptor Table), usada para definir
// segmentos de memória no modo protegido da arquitetura x86.
//
// A entrada possui 8 bytes (64 bits) e deve estar empacotada exatamente conforme
// o formato que o processador espera.
//
// Estrutura da entrada:
//
// Campo           | Tamanho | Descrição
// ----------------|---------|---------------------------------------------------------
// SegLimitLow     | 16 bits | Bits 0-15 do tamanho (limite) do segmento.
// BaseLow         | 16 bits | Bits 0-15 do endereço base do segmento.
// BaseMid         | 8 bits  | Bits 16-23 do endereço base do segmento.
// Access          | 8 bits  | Contém flags que controlam o tipo do segmento, permissões, etc.
// SegLimitHigh    | 4 bits  | Bits 16-19 do limite do segmento (parte alta).
// Gran            | 4 bits  | Flags de granularidade, tamanho e comportamento especial.
// BaseHigh        | 8 bits  | Bits 24-31 do endereço base do segmento.
//
// === DETALHAMENTO DOS CAMPOS ===
//
// SegLimitLow (bits 0-15 do limite)
//     - Define o tamanho total acessível do segmento.
//     - O valor final do limite também considera os bits SegLimitHigh.
//     - Se o bit de granularidade (G) for 1, o limite é multiplicado por 4 KiB.
//
// BaseLow, BaseMid, BaseHigh
//     - Juntos, definem o endereço base de onde o segmento começa na memória.
//     - Montagem:
//           Base = BaseLow | (BaseMid << 16) | (BaseHigh << 24)
//
// Access (8 bits)
//     Bit 7 - P (Presente):
//         - 1 = Segmento está presente na memória
//         - 0 = Fault de segmentação ao acessar
//
//     Bits 5-6 - DPL (Descriptor Privilege Level):
//         - Define o nível de privilégio (0 a 3)
//
//     Bit 4 - S (Descriptor Type):
//         - 1 = Segmento de código/dados
//         - 0 = Descritor de sistema (TSS, LDT, etc)
//
//     Bits 0-3 - Tipo de Segmento:
//         - Define o comportamento do segmento (leitura, execução, expansão etc)
//         - Exemplos:
//             0xA = Código executável, somente leitura
//             0x2 = Dados, leitura/escrita
//
// Gran (4 bits) — bits de controle superiores:
//
//     Bit 7 (G) - Granularidade:
//         - 0 = Limite em bytes
//         - 1 = Limite em blocos de 4 KiB
//
//     Bit 6 (D/B) - Tamanho do operando:
//         - 0 = Segmento de 16 bits
//         - 1 = Segmento de 32 bits
//
//     Bit 5 (L) - Modo Longo (para x86_64):
//         - 0 = Compatível com 32 bits
//         - 1 = Segmento em modo long (64 bits) — normalmente 0 em 32-bit
//
//     Bit 4 - AVL (Disponível para uso do sistema):
//         - Não usado pela CPU, reservado para software
//
// SegLimitHigh (bits 16-19 do limite):
//     - Parte superior do limite total do segmento
//     - É concatenado com SegLimitLow para formar o valor final
//
pub const GDTEntry: type = packed struct {
    SegLimitLow: u16,
    BaseLow: u16,
    BaseMid: u8,
    Access: u8,
    SegLimitHigh: u4,
    Gran: u4,
    BaseHigh: u8,
};

pub const GDTSegments: type = enum(u8) {
    @"kernelcode" = 0x08,
    @"kerneldata" = 0x10,
    @"usercode" = 0x18,
    @"userdata" = 0x20,
};

pub const GDT: type = struct {
    Entries: []GDTEntry,

    pub fn setEntry(
        This: *GDT,
        Entry: GDTSegments,
        Base: u32,
        Limit: u32,
        Gran: u8,
        Access: u8
    ) void {
        if((Entry >> 3) > This.Entries.len) {
            return;
        }

        This.Entries[(@intFromEnum(Entry) >> 3) - 1] {
            .BaseLow = @intCast((Base & 0xFFFF)),
            .BaseMid = @intCast((Base >> 16) & 0xFF),
            .BaseHigh = @intCast((Base >> 24) & 0xFF),
            .SegLimitLow = @intCast(Limit & 0xFFFF),
            .SegLimitHigh = @intCast((Limit >> 16) & 0xF),
            .Access = Access,
            .Gran = @intCast(Gran & 0x0F) 
        };
    }

    pub fn load(This: *GDT) void {
        GDTPointer.Limit = @intCast(This.Entries.len * @sizeOf(GDTEntry) - 1);
        GDTPointer.First = @intFromPtr(&This.Entries[0]);

        asm volatile(
            \\ lgdt (%[GDT])

            \\ movw %[kerneldata], %ax
            \\ movw %ax, %ds
            \\ movw %ax, %ss
            \\ movw %ax, %fs
            \\ movw %ax, %gs
            \\ movw %ax, %es

            \\ ljmp %[kernelcode], $1f

            \\ 1:

            :
            :[GDT] "{eax}" (&GDTPointer),
             [kernelcode] "i" (GDTSegments.@"kernelcode"),
             [kerneldata] "i" (GDTSegments.@"kerneldata")
            : .{}
        );
    }

    pub fn newEntry(Base: u32, Limit: u32, Gran: u8, Access: u8) GDTEntry {
        return GDTEntry {
            .BaseLow = @intCast((Base & 0xFFFF)),
            .BaseMid = @intCast((Base >> 16) & 0xFF),
            .BaseHigh = @intCast((Base >> 24) & 0xFF),
            .SegLimitLow = @intCast(Limit & 0xFFFF),
            .SegLimitHigh = @intCast((Limit >> 16) & 0xF),
            .Access = Access,
            .Gran = @intCast(Gran & 0x0F)
        };
    }
};
