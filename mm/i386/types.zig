// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const AllocPage: type = struct {
    virtual: []u8,
    page: *PageTableEntry,
    master: u8,
    slave: u3,
    zone: Zones,
};

pub const ZoneErr: type = error {
    NonActive,
    NoAlt,
    NonAlloc,
};

pub const Zones: type = enum {
    dma,
    kernel,
    high,
};

pub const Zone: type = struct {
    base: u32,
    virt: u32,
    pages: u32,
    free: u32,
    size: u32,
    last: ?u32,
    table: *[1024]PageTableEntry = @ptrFromInt(0x10), // TMP
    zone: Zones,
    flags: packed struct(u8) {
        active: u1,
        mutex: u1,
        alloc: u1,
        reserved: u5 = 0,
    },
};

pub const AllocPageErr: type = error {
    OutPage,
    Denied,
    DoubleFree,
    NoTableMap,
    DoubleAllocPage,
};

pub const PageDirEntry: type = packed struct {
    present: u1,
    rw: u1,
    user: u1,
    write_thru : u1,
    cache_dis: u1,
    accessed: u1,
    reserved: u1,
    page_size: u1,
    ignored: u1,
    avail: u3,
    table_phys: u20,
};

pub const PageTableEntry: type = packed struct {
    present: u1,
    rw: u1,
    user: u1,
    accessed: u1,
    dirty: u1,
    reserved: u7,
    phys: u20,
};
