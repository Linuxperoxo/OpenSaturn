const arch: type = @import("root").__SaturnArchImpl__.arch;
const buddy: type = @import("root").lib.kernel.alloc.buddy;

const PhysMemory: type = @This();
const PhysPageBuddy: type = buddy.BuddyAllocator(max_order);

pub const PhysPageUsage: type = enum(u2) {
    kernel,
    userspace,
    cache,
};

pub const PhysPage: type = struct {
    id: u32 = 0,
    refcount: u32 = 0,
    division: PhysPageUsage = .kernel,
};

pub const PhysZoneType: type = enum(u2) {
    dma,
    normal,
    kernel,
};

pub const OrderUint: type = @Type(.{
    .int = .{
        .bits = @log2(max_order),
        .signedness = .unsigned,
    },
});

const max_order: comptime_int = 8;
const total_of_phys_pages: comptime_int = @as(usize, 1) << max_order;
const phys_page_size: comptime_int = 4096;

const phys_opensaturn_kernel_zone_start: *anyopaque = @ptrCast(arch.symbols.phys_opensaturn_kernel_zone_start);

phys_pages: [total_of_phys_pages]PhysPage,
phys_buddy: PhysPageBuddy,

pub inline fn init() PhysMemory {
    var phys_pages: [total_of_phys_pages]PhysPage = [_]PhysPage{.{}} ** total_of_phys_pages;

    for (&phys_pages, 0..) |*phys_page, id| {
        phys_page.id = @intCast(id);
    }

    return .{
        .phys_pages = phys_pages,
        .phys_buddy = PhysPageBuddy.init(),
    };
}

pub fn allocAnyPage(self: *PhysMemory, order: OrderUint) ?[]u8 {
    const requested_order: usize = @intCast(order);

    if (self.phys_buddy.alloc(requested_order)) |buddy_block| {
        const pages: usize = @as(usize, 1) << @intCast(buddy_block.order);
        const first_page: usize = buddy_block.first_index;

        const page_id: usize = @intCast(self.phys_pages[first_page].id);
        const address: usize = @intFromPtr(phys_opensaturn_kernel_zone_start) + (page_id * phys_page_size);
        const memory: [*]u8 = @ptrFromInt(address);

        return memory[0 .. pages * phys_page_size];
    }

    return null;
}

pub fn allocByPhysAddrs(self: *PhysMemory, addrs: usize, order: OrderUint) ?[]u8 {
    const base: usize = @intFromPtr(phys_opensaturn_kernel_zone_start);
    const page_mask: usize = phys_page_size - 1;
    const aligned_address: usize = addrs & ~page_mask;

    if (aligned_address < base)
        return null;

    const phys_page_id: usize =  (aligned_address - base) >> comptime(@log2(phys_page_size));

    if (phys_page_id >= total_of_phys_pages)
        return null;

    if (self.phys_buddy.allocAt(phys_page_id, order)) |_| {
        return @as([*]u8, @ptrFromInt(aligned_address))[0..(@as(usize, 1) << @intCast(order)) * phys_page_size];
    }

    return null;
}
