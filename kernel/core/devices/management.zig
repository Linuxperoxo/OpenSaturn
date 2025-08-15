// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Dev_T: type = @import("types.zig").Dev_T;
const DevErr_T: type = @import("types.zig").Dev_T.err_T;

pub fn register_dev(
    dev: Dev_T,
) DevErr_T!usize {
    _ = dev;
}

pub fn unregister_dev(
    dev: Dev_T,
) DevErr_T!usize {
    _ = dev;
}
