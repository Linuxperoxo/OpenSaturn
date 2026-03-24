// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: hashtable.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub fn buildHashTable(
    comptime key_T: type,
    comptime data_T: type,
    comptime table_size: ?usize,
    comptime hash_gen_fn: ?*const fn(data_T) key_T,
) type {
    return struct {
        comptime {
            switch(@typeInfo(key_T)) {
                .int, .float => {},

                .pointer => |ptr| {
                    if(ptr.size != .slice or ptr.child != u8)
                        @compileError("");
                },

                .array => |arr| {
                    if(arr.child != u8)
                        @compileError("");
                },

                else => @compileError(
                    ""
                ),
            }
        }

        const ListHead_T: type = struct {
            first: *Node_T,
            last: *Node_T,
        };
        
        const Node_T: type = struct {
            key: key_T,
            data: data_T,
            next: ?*Node_T,
        };

        pub const Err_T: type = error {
            AllocatorFailed,
            KeyCollision,
        };

        table: [table_size orelse 24]?ListHead_T = [_]?ListHead_T {
            null
        } ** (table_size orelse 24),

        // internal fn

        inline fn default_hash_gen(key: key_T) usize {
            return key ^ (key >> 2);
        }

        inline fn cmp_key(node: *Node_T, key: key_T) bool {
            return node.key == key;
        }

        inline fn find_by_key(list_head: *ListHead_T, key: key_T) ?*Node_T {
            var current_node: *Node_T = list_head.first;
            while(current_node.next != null) : (current_node = current_node.next.?) {
                if(cmp_key(current_node, key))
                    return current_node;
            }
            return null;
        }

        // hashtable fn

        pub fn add(self: *@This(), key: key_T, data: data_T, allocator: anytype) Err_T!void {
            const table_index: usize = (if(hash_gen_fn == null) default_hash_gen(key)
                else hash_gen_fn.?(key)) % self.table.len;

            const list_head: *?ListHead_T = &self.table[table_index];

            if(list_head.* == null) {
                const first_node: *Node_T = &(allocator.alloc(Node_T, 1)
                    catch return Err_T.AllocatorFailed)[0];

                first_node.* = .{
                    .key = key,
                    .data = data,
                    .next = null,
                };

                list_head.* = .{
                    .first = first_node,
                    .last = first_node,
                };
                return;
            }

            if(find_by_key(&list_head.*.?, key)) |_| {
                return Err_T.KeyCollision;
            }

            (&list_head.*.?.last).next = &(allocator.alloc(Node_T, 1)
                catch return Err_T.AllocatorFailed)[0];
            (&list_head.*.?.last).next.?.* = .{
                .key = key,
                .data = data,
                .next = null,
            };
            list_head.*.?.last = (&list_head.*.?.last).next.?;
 
        }

        pub fn del(self: *@This(), key: key_T, allocator: anytype) void {
            _ = self;
            _ = key;
            _ = allocator;
        }

        pub fn search(self: *const @This(), key: key_T) data_T {
            _ = self;
            _ = key;
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

test "Add" {
    const std: type = @import("std");
    const HashTable_T: type = buildHashTable(usize, []const u8, null, null);
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    var allocator = gpa.allocator();
    var hashtable: HashTable_T = .{};

    try hashtable.add(100, "Hello, World!", &allocator);
}