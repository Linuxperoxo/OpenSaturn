// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig      │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Dev_T: type = struct {
    pub const write_T: type = *const fn(data: []const u8) err_T!void;
    pub const read_T: type = *const fn(offset: usize, buffer: []u8) err_T!void;

    pub const type_T: type = enum {
        char,
        block,
    };

    pub const err_T: type = error {
        
    };

    name: []const u8,
    write: write_T,
    read: read_T,
    type: type_T,
};

pub const DevBranch_T: type = struct {
    device: ?Dev_T,
    next: ?*@This(),
    prev: ?*@This(),
};

