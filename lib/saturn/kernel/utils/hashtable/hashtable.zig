// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: hashtable.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub fn buildHashtable(
    comptime Key_T: type,
    comptime Value_T: type,
    comptime root_size: u8,
    comptime hash_gen: ?*const fn(Key_T) u8
) type {
    return struct {
        pub const Node_T: type = struct {
            key: Key_T,
            value: Value_T,
            last: ?*Node_T,
            next: ?*Node_T,
            prev: ?*Node_T,
        };

        pub const Err_T: type = error {
            AllocatorFailed,
            NoNInitialized,
        };

        const hash_gen_fn: *const fn(Key_T) u8 = if(hash_gen != null) hash_gen.? else
            default_hash;

        root: ?*[root_size]?*Node_T,

        // ============ AUX
        inline fn default_hash(key: Key_T) u8 {
            
        }
        // ================

        // ============ OPS
        pub noinline fn init(self: *@This(), allocator: anytype) Err_T!void {
            if(self.root != null) return;
            self.root = &(allocator.alloc([root_size]?Node_T, 1)
                catch return Err_T.AllocatorFailed)[0];
        }

        pub noinline fn deinit(self: *@This(), allocator: anytype) Err_T!void {
            if(self.root == null)
                return Err_T.NoNInitialized;

            for(self.root.?) |node| {
                if(node == null)
                    continue;

                var current: ?*Node_T = node.?.last;
                while(current != null) {
                    // TODO:
                }

                allocator.free(node.?)
                    catch return Err_T.NoNInitialized;
            }
        }

        pub noinline fn store(key: Key_T, value: Value_T, allocator: anytype) Err_T!void {
            
        }

        pub noinline fn write(key: Key_T, value: Value_T) Err_T!void {
            
        }

        pub noinline fn read(key: Key_T) Err_T!Value_T {
            
        }

        pub noinline fn rm(key: Key_T, allocator: anytype) Err_T!void {
            
        }
        // ================
    };
}
