// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: list.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");

pub fn BuildList(comptime T: type) type {
    return struct {
        private: ?*anyopaque = null,

        pub const ListNode_T: type = struct {
            next: ?*@This(),
            prev: ?*@This(),
            data: T,
        };

        const Private_T: type = struct {
            root: ?*ListNode_T,
            iterator: ?*ListNode_T,
            iterator_index: usize,
            eol: ?*ListNode_T,
            nodes: usize,
        };

        pub const ListErr_T: type = error {
            AllocatorErr,
            IndexOutBounds,
            NoNInitialized,
            EndOfIterator,
            NoNNodes,
            NoNNodeFound,
        };

        fn check_allocator(comptime AT: type) void {
            switch(@typeInfo(AT)) {
                .pointer => {},
                else => @compileError(
                    \\ expect pointer to allocator
                ),
            }
        }

        fn find_index(self: *@This(), index: usize) ListErr_T!*ListNode_T {
            const private_casted: *Private_T = @call(.always_inline, cast_private, .{
                self.private.?
            });
            if(private_casted.eol == null) return ListErr_T.NoNInitialized;
            if(index >= private_casted.nodes) return ListErr_T.IndexOutBounds;
            var current = private_casted.root.?;
            for(0..index) |_| {
                current = current.next.?;
            }
            return current;
        }

        inline fn check_init(self: *@This(), comptime ignore_root: bool) ListErr_T!void {
            return if(self.private == null
                or r: {
                    break :r
                        if(!ignore_root) cast_private(self.private.?).root == null else false;
                }) return ListErr_T.NoNInitialized else {};
        }

        inline fn cast_private(private: *anyopaque) *Private_T {
            return @alignCast(@ptrCast(private));
        }

        /// * init the list (use whenever the node quantity is 0)
        pub fn init(self: *@This(), allocator: anytype) ListErr_T!void {
            comptime check_allocator(@TypeOf(allocator));
            self.private = &(allocator.alloc(Private_T, 1) catch return ListErr_T.AllocatorErr)[0];
            cast_private(self.private.?).* = .{
                .root = null,
                .eol = null,
                .iterator = null,
                .iterator_index = 0,
                .nodes = 0,
            };
        }

        /// * add a new no to the end of the list
        pub fn push_in_list(self: *@This(), allocator: anytype, data: T) ListErr_T!void {
            comptime check_allocator(@TypeOf(allocator));
            try self.check_init(true);
            const private_casted: *Private_T = cast_private(self.private.?);
            r: {
                if(private_casted.eol == null) {
                    @branchHint(.unlikely);
                    private_casted.* = .{
                        .root = &(allocator.alloc(ListNode_T, 1) catch return ListErr_T.AllocatorErr)[0],
                        .eol = private_casted.root,
                        .iterator = private_casted.root,
                        .nodes = private_casted.nodes,
                        .iterator_index = private_casted.iterator_index,
                    };
                    private_casted.root.?.* = .{
                        .next = null,
                        .prev = null,
                        .data = data,
                    };
                    break :r {};
                }
                private_casted.eol.?.next = &(allocator.alloc(ListNode_T, 1) catch return ListErr_T.AllocatorErr)[0];
                private_casted.eol.?.next.?.* = .{
                    .next = null,
                    .prev = private_casted.eol,
                    .data = data,
                };
                private_casted.eol = private_casted.eol.?.next;
            }
            private_casted.nodes += 1;
        }

        /// * remove an index from the list
        pub fn drop_on_list(self: *@This(), index: usize, allocator: anytype) ListErr_T!void {
            comptime check_allocator(@TypeOf(allocator));
            try self.check_init(true);
            const private_casted: *Private_T = cast_private(self.private.?);
            if(private_casted.root == null) return ListErr_T.NoNNodes;
            var current: ?*ListNode_T = try @call(.never_inline, find_index, .{
                self, index
            });
            if(current.?.prev != null) {
                current.?.prev.?.next = current.?.next;
            }
            if(current == private_casted.root) {
                private_casted.root = current.?.next;
            }
            if(private_casted.iterator == current) {
                private_casted.iterator = current.?.next;
            }
            const slice: []ListNode_T = @as([*]ListNode_T, @ptrCast(current.?))[0..1];
            allocator.free(
                slice
            ) catch {
                @branchHint(.unlikely);
                if(current.?.prev != null) {
                    @branchHint(.unlikely);
                    current.?.prev.?.next = current;
                }
                return ListErr_T.AllocatorErr;
            };
            private_casted.nodes -= 1;
        }

        /// * places it on an existing index, if it is a new index, it returns an error.
        ///     - to create a new index use push_in_list
        pub fn put_in_index(self: *@This(), index: usize, data: T, allocator: anytype) ListErr_T!void {
            comptime check_allocator(@TypeOf(allocator));
            try self.check_init(true);
            const private_casted: *Private_T = cast_private(self.private.?);
            const node_found: *ListNode_T = try @call(.never_inline, find_index, .{
                self, index
            });
            const new_node: *ListNode_T = &(allocator.alloc(ListNode_T, 1) catch return ListErr_T.AllocatorErr)[0];
            new_node.* = .{
                .next = null,
                .prev = null,
                .data = data,
            };
            r: {
                if(private_casted.root.? == node_found) {
                    private_casted.root = new_node;
                    new_node.next = node_found;
                    node_found.prev = new_node;
                    break :r {};
                }
                new_node.prev = node_found.prev;
                new_node.next = node_found;
                node_found.prev = new_node;
                new_node.prev.?.next = new_node;
            }
            private_casted.nodes += 1;
        }

        /// * access a list index
        pub fn access_by_index(self: *@This(), index: usize) ListErr_T!T {
            return (@call(.always_inline, find_index, .{
                self, index
            }) catch |err| return err).data;
        }

        /// * returns the current index of the iterator, with each call the
        /// iterator pointer moves to the next node
        pub fn iterator(self: *@This()) ListErr_T!T {
            try self.check_init(true);
            const private_casted: *Private_T = cast_private(self.private.?);
            if(private_casted.eol == null) return ListErr_T.NoNInitialized;
            if(private_casted.iterator == null) {
                private_casted.iterator = private_casted.root.?;
                private_casted.iterator_index = 0;
                return ListErr_T.EndOfIterator;
            }
            const current_iterator: *ListNode_T = private_casted.iterator.?;
            private_casted.iterator = private_casted.iterator.?.next;
            private_casted.iterator_index += 1;
            return current_iterator.data;
        }

        /// * returns the index where the iterator is pointing
        pub fn iterator_index(self: *@This()) ListErr_T!usize {
            return if(self.check_init(false)) |_| cast_private(self.private.?).iterator_index
                else |err| return err;
        }

        /// * reset the iterator pointer to the first index
        pub fn iterator_reset(self: *@This()) ListErr_T!void {
            try self.check_init(true);
            cast_private(self.private.?).iterator = cast_private(self.private.?).root;
            cast_private(self.private.?).iterator_index = 0;
        }

        // * takes the value of the last index in the list
        pub fn last_index(self: *@This()) ListErr_T!usize {
            return if(self.check_init(false)) |_| cast_private(self.private.?).*.nodes - 1
                else |err| return err;
        }

        // * gets the number of nodes in the list
        pub fn how_many_nodes(self: *@This()) usize {
            return if(self.check_init(true)) |_| cast_private(self.private.?).nodes
                else |_| 0;
        }
    };
}
