// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Dev_T: type = struct {
    name: []const u8,
    write: *fn(u16, []const u8) anyerror!usize,
    read: *fn(u16, []u8) anyerror!usize,
    ioctrl: *fn(usize, usize) anyerror!usize,
};

pub const DevType_T: type = enum {
    char,
    block,
};

pub const DevErr_T: type = error {
    
};

pub fn register_dev(
    dev: Dev_T,
    devT: DevType_T
) DevErr_T!usize {

}

pub fn unregister_dev(
    name: []const u8
) DevErr_T!usize {
    
}
