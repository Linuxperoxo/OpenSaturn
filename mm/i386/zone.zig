// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: zone.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const page: type = @import("page.zig");
const config: type = @import("root").config;

const Zone: type = @import("types.zig").Zone;
const Zones: type = @import("types.zig").Zones;
const ZoneErr: type = @import("types.zig").ZoneErr;
const PageTableEntry: type = @import("types.zig").PageTableEntry;
const AllocPage: type = @import("types.zig").AllocPage;
const AllocPageErr: type = @import("types.zig").AllocPageErr;

const kernel_page_size = config.kernel.options.kernel_page_size;

// NOTE: a ideia e que o alocador de pagina nao seja extremamente complexo, mas que seja minimalista e eficiente,
// a complexidade real fica no alocador de objetos SOA, ele sera responsavel por gerenciar a pagina, possivelmente
// sera suportado por todas as arquiteturas

pub var zone_dma: Zone = .{
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

pub var zone_kernel: Zone = .{
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

pub var zone_high: Zone = .{
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

const zones = [_]*Zone {
    &zone_dma,
    &zone_kernel,
    &zone_high,
};

pub fn allocZonePage(zone: Zones) AllocPageErr!AllocPage {
    const self: *Zone = zones[@intFromEnum(zone)];
    return r: {
        if(self.flags.alloc == 0) return AllocPageErr.Denied;
        if(self.free == 0) return AllocPageErr.OutPage;
        const phys: u32 = if(self.last) |_| self.last.? + self.size else self.base;
        const base, const offset = t: {
            for(0..comptime(self.table.len / 7)) |i| {
                // verificando se existe alguma pagina livre
                if((~self.table[i * 7].reserved) != 0) {
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
            break :r AllocPageErr.OutPage;
        };
        if(self.table[base + offset].present == 1) return AllocPageErr.DoubleAllocPage;
        self.table[base].reserved |= @as(u7, 0x01) << @intCast(offset);
        self.table[base + offset].phys = @intCast(phys >> 12);
        self.table[base + offset].present = 1;
        self.last = phys;
        self.free -= 1;
        break :r AllocPage {
            .virtual = @as([*]u8, @ptrFromInt(self.virt | ((base + offset) << 12)))[0..self.size],
            .page = &self.table[base + offset],
            .zone = self.zone, // assinatura da zona
            .master = @intCast(base),
            .slave = @intCast(offset),
        };
    };
}

pub fn freeZonePage(
    zone: Zones,
    pg: *const AllocPage
) AllocPageErr!void {
    const self: *Zone = zones[@intFromEnum(zone)];
    if(self.zone != pg.zone) return AllocPageErr.Denied;
    if(pg.page.present == 0) return AllocPageErr.DoubleFree;
    if(@intFromPtr(pg.virtual.ptr) < self.virt and
        @intFromPtr(pg.virtual.ptr) > self.virt + (self.size * self.pages)
    ) return AllocPageErr.Denied;
    pg.page.present = 0;
    pg.page.phys = 0;
    pg.page.rw = 0;
    pg.page.user = 0;
    self.table[pg.master].reserved &= ~(@as(u7, 0x01) << pg.slave);
    self.free += 1;
}

pub fn zoneResize(zone: Zones, base: u32, limit: u32) ZoneErr!void {
    const zone_ptr: *Zone = zones[
        @intFromEnum(zone)
    ];
    if(zone_ptr.flags.mutex == 0) return ZoneErr.NoAlt;
    zone_ptr.base, zone_ptr.pages, zone_ptr.free = .{
        base, limit, if(limit > zone_ptr.free) (limit - zone_ptr.free) else zone_ptr.free
    };
}

pub fn zoneReconf(zone: Zones, flags: u8) ZoneErr!void {
    const zone_ptr: *Zone = zones[
        @intFromEnum(zone)
    ];
    if(zone_ptr.flags.mutex == 0) return ZoneErr.NoAlt;
    // somente para avitar o casting
    asm volatile(
        \\ movl %edx, (%edi)
        :
        :[_] "{edi}" (&zone_ptr.flags),
         [_] "{edx}" (flags)
    );
}

pub fn zoneLock(zone: Zones) void {
    const zone_ptr: *Zone = zones[
        @intFromEnum(zone)
    ];
    zone_ptr.flags.mutex = 0;
}
