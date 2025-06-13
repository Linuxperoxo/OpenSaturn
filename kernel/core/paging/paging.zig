// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: paging.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const PageTableEntry: type = packed struct {
    present: u1,
    rw: u1,
    us: u1,
    write_through: u1,
    cache_disable: u1,
    accessed: u1,
    dirty: u1,
    pat: u1,
    global: u1,
    available: u3,
    phys: u20,
};

pub const PageDirectoryEntry: type = packed struct {
    present: u1,
    rw: u1,
    us: u1,
    write_through: u1,
    cache_disable: u1,
    accessed: u1,
    ignored: u1,
    page_size: u1,
    reserved: u1,
    available: u3,
    table: u20,
};

pub const kpaging align(4096) = fill();
pub const upaging align(4096)= fill();

fn fill() struct {directory: [1024]PageDirectoryEntry, tables: [1024]PageTableEntry} {
    @setEvalBranchQuota(2049);
    return .{
        .directory = init: {
            var dir: [1024]PageDirectoryEntry = undefined;
            for(0..1024) |i| {
                dir[i] = .{
                    .present = 0,
                    .rw = 0,
                    .us = 0,
                    .write_through = 0,
                    .cache_disable = 0,
                    .accessed = 0,
                    .ignored = 0,
                    .page_size = 0,
                    .global = 0,
                    .available = 0,
                    .table = 0,
                };
            }
            break :init dir;
        },
        .tables = init: {
            var tbl: [1024]PageTableEntry = undefined;
            for(0..1024) |i| {
                tbl[i] = .{
                    .present = 0,
                    .rw = 0,
                    .us = 0,
                    .write_through = 0,
                    .cache_disable = 0,
                    .accessed = 0,
                    .dirty = 0,
                    .pat = 0,
                    .global = 0,
                    .available = 0,
                    .phys = 0,
                };
            }
            break :init tbl;
        },
    };
}
