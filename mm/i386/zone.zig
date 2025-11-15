// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: zone.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const page: type = @import("page.zig");
const config: type = @import("root").config;

const Zone_T: type = @import("types.zig").Zone_T;
const Zones_T: type = @import("types.zig").Zones_T;
const ZoneErr_T: type = @import("types.zig").ZoneErr_T;
const PageTableEntry_T: type = @import("types.zig").PageTableEntry_T;
const AllocPage_T: type = @import("types.zig").AllocPage_T;
const AllocPageErr_T: type = @import("types.zig").AllocPageErr_T;

const kernel_page_size = config.kernel.options.kernel_page_size;

// NOTE: a ideia e que o alocador de pagina nao seja extremamente complexo, mas que seja minimalista e eficiente,
// a complexidade real fica no alocador de objetos SOA, ele sera responsavel por gerenciar a pagina, possivelmente
// sera suportado por todas as arquiteturas

pub var zone_dma: Zone_T = .{
    .base = 0x0000_0000,
    .virt = 0, // TODO:
    .pages = 0x0010_0000 / kernel_page_size,
    .free =  0x0010_0000 / kernel_page_size,
    .size = kernel_page_size,
    .zone = .dma,
    .last = null,
    .flags = .{
        .active = 1,
        .mutex = 0,
        .alloc = 1,
    },
};

pub var zone_kernel: Zone_T = .{
    .base = 0, // kernel phys data end align(4096)
    .virt = page.kernel_index[@intFromEnum(page.KernelPageIndex.paged)],
    .pages = 0,
    .free =  0,
    .size = kernel_page_size,
    .zone = .kernel,
    .table = &page.kernel_page_table_virtual[@intFromEnum(page.KernelPageIndex.paged)],
    .last = null,
    .flags = .{
        .active = 1,
        .mutex = 1,
        .alloc = 0,
    },
};

pub var zone_high: Zone_T = .{
    .base = 0x1000_0000,
    .virt = 0, // TODO:
    .pages = 0,
    .free =  0,
    .size = kernel_page_size,
    .zone = .high,
    .last = null,
    .flags = .{
        .active = 0,
        .mutex = 1,
        .alloc = 0,
    },
};

const zones = [_]*Zone_T {
    &zone_dma,
    &zone_kernel,
    &zone_high,
};

pub fn alloc_zone_page(
    zone: if(@import("builtin").is_test) *Zone_T else Zones_T,
) AllocPageErr_T!AllocPage_T {
    const self: *Zone_T = switch(@typeInfo(@TypeOf(zone))) {
        .pointer => zone,
        else => zones[
            @intFromEnum(zone)
        ],
    };
    return r: {
        if(self.flags.alloc == 0) return AllocPageErr_T.Denied;
        if(self.free == 0) return AllocPageErr_T.OutPage;
        const phys: u32 = if(self.last) |_| self.last.? + self.size else self.base;
        const base, const offset = t: {
            for(0..comptime(self.table.len / 7)) |i| {
                // verificando se existe alguma pagina livre
                if((self.table[i * 7].reserved ^ @as(u7, 0b111_1111)) != 0) {
                    for(0..7) |j| {
                        if(((self.table[i * 7].reserved >> @intCast(j)) & 0x01) == 0) {
                            break :t .{
                                i * 7,
                                j,
                            };
                        }
                    }
                }
            }
            break :r AllocPageErr_T.OutPage;
        };
        if(self.table[base + offset].present == 1) return AllocPageErr_T.DoubleAllocPage;
        self.table[base].reserved |= @as(u7, 0x01) << @intCast(offset);
        self.table[base + offset].phys = @intCast(phys >> 12);
        self.table[base + offset].present = 1;
        self.last = phys;
        self.free -= 1;
        break :r AllocPage_T {
            .virtual = @as([*]u8, @ptrFromInt(self.virt | ((base + offset) << 12)))[0..self.size],
            .page = &self.table[base + offset],
            .zone = self.zone, // assinatura da zona
            .master = @intCast(base),
            .slave = @intCast(offset),
        };
    };
}

pub fn free_zone_page(
    zone: if(@import("builtin").is_test) *Zone_T else Zones_T,
    pg: *const AllocPage_T
) AllocPageErr_T!void {
    const self: *Zone_T = switch(@typeInfo(@TypeOf(zone))) {
        .pointer => zone,
        else => zones[
            @intFromEnum(zone)
        ],
    };
    if(self.zone != pg.zone) return AllocPageErr_T.Denied;
    if(pg.page.present == 0) return AllocPageErr_T.DoubleFree;
    if(@intFromPtr(pg.virtual.ptr) < self.virt and
        @intFromPtr(pg.virtual.ptr) > self.virt + (self.size * self.pages)
    ) return AllocPageErr_T.Denied;
    pg.page.present = 0;
    pg.page.phys = 0;
    pg.page.rw = 0;
    pg.page.user = 0;
    self.table[pg.master].reserved &= ~(@as(u7, 0x01) << pg.slave);
    self.free += 1;
}

pub fn zone_resize(zone: Zones_T, base: u32, limit: u32) ZoneErr_T!void {
    const zone_ptr: *Zone_T = zones[
        @intFromEnum(zone)
    ];
    if(zone_ptr.flags.mutex == 0) return ZoneErr_T.NoAlt;
    zone_ptr.base, zone_ptr.pages, zone_ptr.free = .{
        base, limit, if(limit > zone_ptr.free) (limit - zone_ptr.free) else zone_ptr.free
    };
}

pub fn zone_reconf(zone: Zones_T, flags: u8) ZoneErr_T!void {
    const zone_ptr: *Zone_T = zones[
        @intFromEnum(zone)
    ];
    if(zone_ptr.flags.mutex == 0) return ZoneErr_T.NoAlt;
    // somente para avitar o casting
    asm volatile(
        \\ movl %edx, (%edi)
        :
        :[_] "{edi}" (&zone_ptr.flags),
         [_] "{edx}" (flags)
    );
}

pub fn zone_lock(zone: Zones_T) void {
    const zone_ptr: *Zone_T = zones[
        @intFromEnum(zone)
    ];
    zone_ptr.flags.mutex = 0;
}
