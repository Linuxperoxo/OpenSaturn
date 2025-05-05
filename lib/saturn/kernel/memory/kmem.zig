// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kmem.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Como esse esses allocs vão ser usado para o próprio kernel,
// ele não será muito robusto, será apenas para pequenas alocações
// de memória para coisas como o modulos, arquivos virtuais(dev,proc,sys), etc

const FirtsPageAddrs: comptime_int = 0xE000000;
const DefaultSizePerPage: comptime_int = 0x100;
const TotalOfPageDir: comptime_int = 0x100;
const PagePerPageDir: comptime_int = 16;

var pageDirectories = init: {
    @setEvalBranchQuota(TotalOfPageDir * PagePerPageDir);
    var directories: [TotalOfPageDir]pageDirectory = undefined;
    for(0..TotalOfPageDir - 1) |pagedir| {
        for(0..PagePerPageDir - 1) |page| {
            directories[pagedir].pages[page].alloc = .free;
            directories[pagedir].pages[page].type = .master;
        }
    }
    break :init directories;
};

// TODO: Otimização de busca por páginas livres (no momento não 
//       está sendo utilizada)
var pageFreeIndex: struct {
    directory:  u16,
    page: u16,
} = .{
    .directory = 0,
    .page = 0,
};

const pageAllocFlags: type = enum(u1) {
    free,
    busy,
};

const pageTypeFlags: type = enum(u1) {
    master,
    slave,
};

const pageDirectory: type = struct {
    pages: [PagePerPageDir]pageFlags = undefined,
};

// Flags:
//
// Bit 0: Diz se a página foi alocada 
// Bit 1: Diz se é uma página master ou slave. Por enquanto não está sendo usado,
//        mas vai ser importante para alocar e desalocar paginas em sequência
// Bit 2: Reservado
// Bit 3: Reservado
const pageFlags: type = packed struct {
    alloc: pageAllocFlags,
    type: pageTypeFlags,
};

const allocatorError: type = error {
    OutOfMemory,
    MemoryFragmentation,
};

pub fn kmalloc(
    comptime T: type,
    N: u8
) allocatorError![]T {
    var directory: u16 = 0;
    var page: u16 = 0;
    while(directory < comptime TotalOfPageDir) : 
        (directory += 1) {
        while(page < comptime PagePerPageDir) : 
            (page += 1) {
            // TODO: Adicionar suporte a alocação de páginas consecutivas
            if(pageDirectories[directory].pages[page].alloc == .free) {
                pageDirectories[directory].pages[page].alloc = .busy;
                pageDirectories[directory].pages[page].type = .master;
                return @as(
                    []T,
                    @as(
                        [*]T,
                        @ptrFromInt(
                            (FirtsPageAddrs + 
                            (@as(u32, directory) * PagePerPageDir * DefaultSizePerPage) + 
                            (@as(u32, page) * DefaultSizePerPage))
                        )
                    )[0..(N - 1)]
                );
            }
        }
        page = 0;
    }
    return allocatorError.OutOfMemory;
}

pub fn kfree(
    P: *anyopaque
) void {
    const dirIndex: u16 = @intCast((@intFromPtr(P) & 0x00FF000) >> 12);
    const pageIndex: u16 = @intCast((@intFromPtr(P) & 0x0000F00) >> 8);

    pageDirectories[dirIndex].pages[pageIndex].alloc = .free;
    
    var directory: u16 = dirIndex;
    var page: u16 = pageIndex + 1;
    while(directory < comptime TotalOfPageDir) : 
         (directory += 1) {
        while(page < comptime PagePerPageDir) : 
             (page += 1) {
            if(pageDirectories[directory].pages[page].alloc == .busy and 
                pageDirectories[directory].pages[page].type == .slave) {
                pageDirectories[directory].pages[page].alloc = .free;
            }

            if(pageDirectories[directory].pages[page].alloc == .free or
                pageDirectories[directory].pages[page].type == .master) {
                return;
            }
        }
        page = 0;
    }
}
