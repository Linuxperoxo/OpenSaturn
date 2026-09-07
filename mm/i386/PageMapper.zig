// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: PageMapper.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const PageMapper: type = @This();
const PhysMemory: type = @import("PhysMemory.zig");

pub const entries_per_table: comptime_int = 1024;
pub const page_size_shift: comptime_int = 12;
pub const page_size: comptime_int = 1 << page_size_shift;

pub const Error: type = error{
    BusyPage,
};

pub const PageDir: type = packed struct {
    present: u1 = 0,
    rw: u1 = 0,
    user: u1 = 0,
    write_thru: u1 = 0,
    cache_dis: u1 = 0,
    accessed: u1 = 0,
    reserved: u1 = 0,
    page_size: u1 = 0,
    ignored: u1 = 0,
    avail: u3 = 0,
    table_phys: u20 = 0,
};

pub const VirtualPage: type = packed struct {
    present: u1 = 0,
    rw: u1 = 0,
    user: u1 = 0,
    write_thru: u1 = 0,
    cache_dis: u1 = 0,
    accessed: u1 = 0,
    dirty: u1 = 0,
    pat: u1 = 0,
    global: u1 = 0,
    avail: u3 = 0,
    phys: u20 = 0,
};

pub const PageDirectory: type = [entries_per_table]PageDir;
pub const PageTable: type = [entries_per_table]VirtualPage;
pub const PageTables: type = [entries_per_table]*PageTable;

page_dirs: *PageDirectory,
page_tables: *PageTables,
phys_memory: *PhysMemory,

inline fn indexForVirtualAddrs(addrs: u32) struct { u10, u10 } {
    return .{
        @truncate(addrs >> 22),
        @truncate(addrs >> page_size_shift),
    };
}

pub inline fn init(
    page_dirs: *PageDirectory,
    page_tables: *PageTables,
    phys_memory: *PhysMemory,
) PageMapper {
    var page_directory: PageMapper = .{
        .page_dirs = page_dirs,
        .page_tables = page_tables,
        .phys_memory = phys_memory,
    };

    for (0..entries_per_table) |i| {
        const page_table = page_directory.page_tables[i];

        page_directory.page_dirs[i] = .{
            .present = 1,
            .rw = 1,
            .page_size = 0,
            .table_phys = @truncate(
                @intFromPtr(page_table) >> page_size_shift,
            ),
        };
    }

    return page_directory;
}

pub inline fn allocPageByVirtualAddrs(self: *const PageMapper, virtual: u32, phys: u32) Error!*VirtualPage {
    const page_dir_index: u10, const page_table_index: u10 = indexForVirtualAddrs(virtual);

    const page_dir: PageDir = self.page_dirs[page_dir_index];
    const page_table: *align(page_size) PageTable = @ptrFromInt(
        @as(usize, page_dir.table_phys) << page_size_shift,
    );
    const page: *VirtualPage = &page_table[page_table_index];

    if (page.present == 1)
        return Error.BusyPage;

    page.phys = @truncate(phys >> page_size_shift);
    page.present = 1;
    page.rw = 1;

    return page;
}

pub inline fn allocPageByIdentityMapping(self: *const PageMapper, phys: u32) Error!*VirtualPage {
    return self.allocPageByVirtualAddrs(phys, phys);
}

pub inline fn enableThisPageDir(self: *const PageMapper) void {
    asm volatile (
        \\ movl %eax, %cr0
        :
        : [_] "eax" (self.page_dirs),
    );
}
