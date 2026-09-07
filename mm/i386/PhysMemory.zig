const PhysMemory: type = @This();

pub const PhysPageDivision: type = enum(u2) {
    kernel,
    userspace,
    cache,
};

pub const PhysPage: type = struct {
    id: u32 = 0,
    refcount: u32 = 0,
    division: PhysPageDivision = .kernel,
    free: bool = true,
};

pub const PhysZoneType: type = enum(u2) {
    dma,
    normal,
    kernel,
};

pub const FreeArea: type = struct {
    first_page: u32 = 0,
    page_count: u32 = 0,
};

pub const PhysZone: type = struct {
    zone_type: PhysZoneType,
    first_page: u32,
    page_count: u32,

    free_area: FreeArea,
};

pub const total_phys_pages: comptime_int = 128;

// Exemplo:
// DMA    = 16 páginas
// NORMAL = 80 páginas
// KERNEL = 32 páginas
pub const zone_dma_total_pages: comptime_int = 16;
pub const zone_normal_total_pages: comptime_int = 80;
pub const zone_kernel_total_pages: comptime_int = 32;

phys_pages: [total_phys_pages]PhysPage,
memory_zones: [3]PhysZone,

pub inline fn init() PhysMemory {
    var phys_pages = [_]PhysPage{
        .{}
    } ** total_phys_pages;

    for (&phys_pages, 0..) |*phys_page, id| {
        phys_page.id = @intCast(id);
    }

    var zones: [3]PhysZone = undefined;

    // ----------------------------------------
    // DMA
    // ----------------------------------------

    zones[0] = .{
        .zone_type = .dma,
        .first_page = 0,
        .page_count = zone_dma_total_pages,

        .free_area = .{
            .first_page = 0,
            .page_count = zone_dma_total_pages,
        },
    };

    // ----------------------------------------
    // NORMAL
    // ----------------------------------------

    zones[1] = .{
        .zone_type = .normal,
        .first_page = zone_dma_total_pages,
        .page_count = zone_normal_total_pages,

        .free_area = .{
            .first_page = zone_dma_total_pages,
            .page_count = zone_normal_total_pages,
        },
    };

    // ----------------------------------------
    // KERNEL
    // ----------------------------------------

    zones[2] = .{
        .zone_type = .kernel,
        .first_page = zone_dma_total_pages + zone_normal_total_pages,
        .page_count = zone_kernel_total_pages,

        .free_area = .{
            .first_page = zone_dma_total_pages + zone_normal_total_pages,
            .page_count = zone_kernel_total_pages,
        },
    };

    return .{
        .phys_pages = phys_pages,
        .memory_zones = zones,
    };
}
