// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: hash_map.zig  │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const mem: type = @import("root").lib.kernel.mem;

fn type_resolver(t: type) enum { num, string, other } {
    return switch (@typeInfo(t)) {
        .int, .float => .num,
        .pointer => |ptr| if (ptr.size != .slice or ptr.child != u8) .other else .string,
        else => .other,
    };
}

pub fn HashMap(
    comptime key_T: type,
    comptime data_T: type,
    comptime table_size: ?usize,
    comptime hash_gen_fn: ?*const fn (key_T) usize,
) type {
    return struct {
        comptime {
            if (type_resolver(key_T) == .other) @compileError("hashtable_builder: expected key_T to be an integer, float or string");
        }

        const ListHead_T: type = struct {
            first: ?*Node_T,
            last: ?*Node_T,
        };

        const Node_T: type = struct {
            key: key_T,
            data: data_T,
            next: ?*Node_T,
            prev: ?*Node_T,
        };

        pub const Err_T: type = error{
            AllocatorFailed,
            KeyCollision,
            KeyNotFound,
        };

        table: [table_size orelse 16]ListHead_T = [_]ListHead_T{
            ListHead_T{
                .first = null,
                .last = null,
            },
        } ** (table_size orelse 16),

        // internal fn

        inline fn default_hash_gen(key: key_T) usize {
            return sw: switch (comptime type_resolver(key_T)) {
                // *% mult with overflow
                .num => break :sw key *% @as(usize, ~0),
                .string => {
                    const fnv_prime: usize = @truncate(1099511628211);
                    var hash: usize = @truncate(14695981039346656037);
                    for (key) |char| {
                        hash = hash ^ char;
                        hash = hash *% fnv_prime;
                    }
                    break :sw hash;
                },
                .other => unreachable,
            };
        }

        inline fn cmp_key(node: *Node_T, key: key_T) bool {
            return sw: switch (comptime type_resolver(key_T)) {
                .num => break :sw node.key == key,
                .string => break :sw mem.eql(key, node.key, .{}),
                .other => unreachable,
            };
        }

        inline fn find_by_key(list_head: *const ListHead_T, key: key_T) ?*Node_T {
            var current_node: ?*Node_T = list_head.first;
            while (current_node != null) : (current_node = current_node.?.next) {
                if (cmp_key(current_node.?, key))
                    return current_node;
            }
            return null;
        }

        inline fn hash_gen(key: key_T) usize {
            return if (hash_gen_fn != null) hash_gen_fn.?(key) else default_hash_gen(key);
        }

        // hashtable fn

        pub fn add(self: *@This(), key: key_T, data: data_T, allocator: anytype) Err_T!void {
            const table_index: usize = hash_gen(key) % self.table.len;
            const list_head: *ListHead_T = &self.table[table_index];

            if (list_head.first == null) {
                const first_node: *Node_T = @ptrCast((allocator.alloc(Node_T, 1) catch return Err_T.AllocatorFailed).ptr);

                first_node.* = .{
                    .key = key,
                    .data = data,
                    .next = null,
                    .prev = null,
                };

                list_head.* = .{
                    .first = first_node,
                    .last = first_node,
                };
                return;
            }

            if (find_by_key(list_head, key)) |_| {
                return Err_T.KeyCollision;
            }

            const current_last: *Node_T = list_head.last.?;

            current_last.next = @ptrCast((allocator.alloc(Node_T, 1) catch return Err_T.AllocatorFailed).ptr);
            current_last.next.?.* = .{
                .key = key,
                .data = data,
                .next = null,
                .prev = current_last,
            };

            list_head.last = current_last.next;
        }

        pub fn del(self: *@This(), key: key_T, allocator: anytype) Err_T!void {
            const table_index: usize = hash_gen(key) % self.table.len;
            const list_head: *ListHead_T = &self.table[table_index];

            if (list_head.first == null)
                return Err_T.KeyNotFound;

            if (find_by_key(list_head, key)) |node| {
                if (node == list_head.first.?) {
                    if (node.next == null) {
                        list_head.* = .{
                            .first = null,
                            .last = null,
                        };
                    } else {
                        list_head.first = node.next;
                    }
                } else {
                    node.prev.?.next = node.next;
                }
                allocator.free(node[0..1]) catch return Err_T.AllocatorFailed;
            }
        }

        pub fn search(self: *const @This(), key: key_T) Err_T!data_T {
            const table_index: usize = hash_gen(key) % self.table.len;
            const list_head: *const ListHead_T = &self.table[table_index];

            if (list_head.first == null)
                return Err_T.KeyNotFound;

            if (find_by_key(list_head, key)) |found| return found.data else return Err_T.KeyNotFound;
        }

        pub fn test_collision(self: *const @This(), key: key_T) bool {
            _ = self.search(key) catch return false;
            return true;
        }
    };
}
