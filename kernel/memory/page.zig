// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: page.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Aqui, vamos disponibilizar paginas para recursos
// internos do kernel, ou seja, qualquer gerenciador
// de memoria vai ter que pedir uma pagina para poder
// fazer suas alocaçoes internas, esse codigo e totalmente
// responsavel por disponibilizar memoria para outros recursos

// NOTE: No momento nao vamos usar memoria virtual para isso,
//       apenas memoria fisica

const GlobalBase: comptime_int = 0xE000000;
const DefaultSizePerPage: comptime_int = 0x100;
const TotalOfPageDir: comptime_int = 0x100;
const PagePerPageDir: comptime_int = 16;
const MaxAllocators: comptime_int = 16;

const Directory: type = struct {
    pages: [PagePerPageDir]Page,
    free: u8 = 0, // Aponta para o indice da pagina livre mais baixa
};

const Page: type = struct {
    alloc: enum {free, busy} = .free,
    typeof: enum {undef, master, slave} = .undef,
};

const Errors: type = error {
    LimitOverflow,
    OutOfMemory,
    MaxRangeOverflow,
    DoubleFree,
    Undefined,
    AllocatorError,
    OutOfAllocator,
    DoubleDelAllocator,
};

const AllocatorCtx: type = struct {
    flags: enum {sleep, busy, reserved} = .sleep,
    allocator: PageAllocator,
};

const PageAllocator: type = struct {
    directories: [TotalOfPageDir]Directory,

    pub fn allocPage(
        self: *PageAllocator, 
        size: u8 // Quantidade de paginas para alocar
    ) Errors![]u8 {
        
    }

    pub fn freePage(
        self: *PageAllocator, 
        page: [*]anyopaque
    ) Errors!void {
        
    }
};

var AllocatorsInfo: struct {
    allocators: [MaxAllocators]AllocatorCtx,
    free: ?u4 = null,
} = .{};

pub fn wakeAllocator() Errors!u8 {
    // Carregando as informaçoes dos alocadores no cache mais alto (L1).
    // Decidi usar o @prefetch pela seguinte ideia, se alguem pediu um 
    // novo alocador, e pq provavelmente vai usa-lo, entao deixar no cache
    // para acelerar esse processo e uma boa ideia
    // NOTE: Isso nao e totalmente necessario, mas como e uma parte que
    //       sempre vai ser usada pelo kernel, e interessante deixar um
    //       hot cache
    @prefetch(&AllocatorsInfo, .{
        .cache = .data,
        .locality = 1,
        .rw = .read,
    });
    return ret: {
        if(AllocatorsInfo.free) |_| {
            for(0..15) |i| {
                if(AllocatorsInfo.allocators[i].flags == .sleep) {
                    AllocatorsInfo.allocators[i].flags = .busy;
                    break :ret i;
                }
            }
            break :ret Errors.OutOfAllocator;
        }
        break :ret AllocatorsInfo.free.?;
    };
}

pub fn sleepAllocator(
    allocDesc: u8
) Errors!void {
    const ad: u4 = @intCast(allocDesc & 0x0F);
    if(AllocatorsInfo.allocators[ad].flags == .sleep) {
        return Errors.DoubleDelAllocator;
    }
    AllocatorsInfo.allocators[ad].flags = .sleep;
    if(AllocatorsInfo.free == null or AllocatorsInfo.free.? > ad) {
        AllocatorsInfo.free = ad;
    }
}

pub fn allocPage(
    allocDesc: u8,
    size: u8
) Errors![]u8 {
    const ad: u4 = allocDesc & 0x0F;
    if(AllocatorsInfo.allocators[ad].flags == .sleep) {
        return Errors.AllocatorError;
    }
    return @call(.always_inline, &PageAllocator.allocPage, .{
        &AllocatorsInfo.allocators[ad],
        size,
    });
}

pub fn freePage(
    allocDesc: u8,
    page: [*]anyopaque
) Errors!void {
    const ad: u4 = allocDesc & 0x0F;
    if(AllocatorsInfo.allocators[ad].flags == .free) {
        return Errors.AllocatorError;
    }
    return @call(.always_inline, &PageAllocator.freePage, .{
        &AllocatorsInfo.allocators[ad],
        page,
    });
}
