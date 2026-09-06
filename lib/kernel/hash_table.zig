// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: hash_map.zig  │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const mem: type = @import("root").lib.kernel.mem;

fn typeResolver(t: type) enum { num, string, other } {
    return switch (@typeInfo(t)) {
        .int, .float => .num,
        .pointer => |ptr| if (ptr.size != .slice or ptr.child != u8) .other else .string,
        else => .other,
    };
}

pub fn hashMap(
    comptime key_type: type,
    comptime data_type: type,
    comptime table_size: ?usize,
    comptime hashGenFn: ?*const fn (key_type) usize,
) type {
    return struct {
        comptime {
            if (typeResolver(key_type) == .other) @compileError("hashtable_builder: expected Key to be an integer, float or string");
        }

        const ListHead: type = struct {
            first: ?*Node,
            last: ?*Node,
        };

        const Node: type = struct {
            key: key_type,
            data: data_type,
            next: ?*Node,
            prev: ?*Node,
        };

        pub const Err: type = error{
            AllocatorFailed,
            KeyCollision,
            KeyNotFound,
        };

        table: [table_size orelse 16]ListHead = [_]ListHead{
            ListHead{
                .first = null,
                .last = null,
            },
        } ** (table_size orelse 16),

        // internal fn

        inline fn defaultHashGen(key: key_type) usize {
            return sw: switch (comptime typeResolver(key_type)) {
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

        inline fn cmpKey(node: *Node, key: key_type) bool {
            return sw: switch (comptime typeResolver(key_type)) {
                .num => break :sw node.key == key,
                .string => break :sw mem.eql(key, node.key, .{}),
                .other => unreachable,
            };
        }

        inline fn findByKey(list_head: *const ListHead, key: key_type) ?*Node {
            var current_node: ?*Node = list_head.first;
            while (current_node != null) : (current_node = current_node.?.next) {
                if (cmpKey(current_node.?, key))
                    return current_node;
            }
            return null;
        }

        inline fn hashGen(key: key_type) usize {
            return if (hashGenFn != null) hashGenFn.?(key) else defaultHashGen(key);
        }

        // hashtable fn

        pub fn add(self: *@This(), key: key_type, data: data_type, allocator: anytype) Err!void {
            const table_index: usize = hashGen(key) % self.table.len;
            const list_head: *ListHead = &self.table[table_index];

            if (list_head.first == null) {
                const first_node: *Node = @ptrCast((allocator.alloc(Node, 1) catch return Err.AllocatorFailed).ptr);

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

            if (findByKey(list_head, key)) |_| {
                return Err.KeyCollision;
            }

            const current_last: *Node = list_head.last.?;

            current_last.next = @ptrCast((allocator.alloc(Node, 1) catch return Err.AllocatorFailed).ptr);
            current_last.next.?.* = .{
                .key = key,
                .data = data,
                .next = null,
                .prev = current_last,
            };

            list_head.last = current_last.next;
        }

        pub fn del(self: *@This(), key: key_type, allocator: anytype) Err!void {
            const table_index: usize = hashGen(key) % self.table.len;
            const list_head: *ListHead = &self.table[table_index];

            if (list_head.first == null)
                return Err.KeyNotFound;

            if (findByKey(list_head, key)) |node| {
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
                allocator.free(node[0..1]) catch return Err.AllocatorFailed;
            }
        }

        pub fn search(self: *const @This(), key: key_type) Err!data_type {
            const table_index: usize = hashGen(key) % self.table.len;
            const list_head: *const ListHead = &self.table[table_index];

            if (list_head.first == null)
                return Err.KeyNotFound;

            if (findByKey(list_head, key)) |found| return found.data else return Err.KeyNotFound;
        }

        pub fn testCollision(self: *const @This(), key: key_type) bool {
            _ = self.search(key) catch return false;
            return true;
        }
    };
}
