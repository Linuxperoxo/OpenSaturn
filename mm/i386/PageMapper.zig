const PageMapper: type = @This();

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

pub const Page: type = packed struct {
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

page_dirs: *[1024]PageDir,
page_tables: *[1024]*[1024]Page,

inline fn indexForVirtualAddrs(addrs: u32) struct { u10, u10 } {
    return .{
        @truncate(addrs >> 22),
        @truncate(addrs >> 12),
    };
}

pub inline fn init(
    page_dirs: *[1024]PageDir,
    page_tables: *[1024]*[1024]Page,
) PageMapper {
    var page_directory: PageMapper = .{
        .page_dirs = page_dirs,
        .page_tables = page_tables,
    };

    for (0..1024) |i| {
        const page_table = page_directory.page_tables[i];

        page_directory.page_dirs[i] = .{
            .present = 1,
            .rw = 1,
            .page_size = 0,
            .table_phys = @truncate(
                @intFromPtr(page_table) >> 12,
            ),
        };
    }

    return page_directory;
}

pub inline fn allocPageByVirtualAddrs(self: *const PageMapper, virtual: u32, phys: u32) Error!*Page {
    const page_dir_index: u10, const page_table_index: u10 = indexForVirtualAddrs(virtual);

    const page_dir: PageDir = self.page_dirs[page_dir_index];
    const page_table: *align(4096) [1024]Page = @ptrFromInt(@as(usize, page_dir.table_phys) << 12);
    const page: *Page = &page_table[page_table_index];

    if (page.present == 1)
        return Error.BusyPage;

    page.phys = @truncate(phys >> 12);
    page.present = 1;
    page.rw = 1;

    return page;
}

pub inline fn allocPageByIdentityMapping(self: *const PageMapper, phys: u32) Error!*Page {
    return self.allocPageByVirtualAddrs(phys, phys);
}

pub inline fn enableThisPageDir(self: *const PageMapper) void {
    asm volatile(
        \\ movl %eax, %cr0
        :
        :[_] "eax" (self.page_dirs)
    );
}
