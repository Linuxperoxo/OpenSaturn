// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: hashtable.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub fn buildHashtable(
    comptime K: type,
    comptime T: type,
    comptime max_index: u8,
    comptime root_size: u2,
    comptime hash_gen: ?*const fn(anytype) u8
) type {
    return struct {
        private: ?*anyopaque = null,

        const HashtableInfo_T: type = struct {
            root_ptr: ?*[max_index]?*HashtableRootNode_T,
        };

        const HashtableRootNode_T: type = struct {
            root: ?*[root_size]?*HashtableNode_T,
        };

        const HashtableNode_T: type = struct {
            next: ?*@This(),
            prev: ?*@This(),
            key: K,
            data: T,
        };

        fn cast_private(self: *const @This()) *HashtableInfo_T {
            // is_initialized after call this fn
            return @ptrCast(@alignCast(self.private.?));
        }

        pub fn is_initialized(self: *const @This()) bool {
            return (self.private != null and s);
        }
    };
}
