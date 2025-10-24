// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const zone: type = @import("zone.zig");
const types: type = @import("types.zig");

var zone_test: types.Zone_T = .{
    .base = 0x0010_B000,
    .virt = 0xC000_0000,
    .pages = 32,
    .free =  32,
    .size = 4096,
    .zone = .kernel,
    .table = &page_table_test,
    .last = null,
    .flags = .{
        .active = 1,
        .mutex = 0,
        .alloc = 1,
    },
};

var page_table_test: [1024]types.PageTableEntry_T = [_]types.PageTableEntry_T {
    types.PageTableEntry_T {
        .present = 0,
        .rw = 0,
        .user = 0,
        .accessed = 0,
        .dirty = 0,
        .reserved = 0,
        .phys = 0,
    },
} ** 1024;

const TestErr_T: type = error {
    UnreachableTestCode,
    UndefinedAction,
};

test "Zone Alloc Test" {
    var page_old: ?types.AllocPage_T = null;
    for(0..zone_test.pages) |_| {
        const page_new = try zone.alloc_zone_page(&zone_test);
        if(page_old) |_| {
            if(
                @intFromPtr(page_old.?.virtual.ptr) <= @intFromPtr(page_new.virtual.ptr) and
                (page_new.virtual.ptr - page_new.virtual.len) != page_old.?.virtual.ptr
            ) return TestErr_T.UndefinedAction;
        }
        page_old = page_new;
    }
    _ = zone.alloc_zone_page(&zone_test) catch |err| {
        switch(err) {
            types.AllocPageErr_T.OutPage => {},
            else => return TestErr_T.UnreachableTestCode,
        }
    };
}
