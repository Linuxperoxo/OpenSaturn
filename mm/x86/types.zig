// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const AllocPage_T: type = struct {
    virtual: [*]anyopaque,
    page: *PageTableEntry_T,
    len: usize,
    zone: enum {
        high,
        normal,
        dma,
    },
};

pub const AllocPageErr_T: type = error {
    OutPage,
    DoubleFree
};

pub const PageDirEntry_T: type = packed struct {
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

pub const PageTableEntry_T: type = packed struct {
    present: u1,
    rw: u1,
    user: u1,
    accessed: u1,
    dirty: u1,
    reserved: u7,
    phys: u20,
};
