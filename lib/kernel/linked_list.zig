// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: linked_list.zig │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub fn buildList(comptime t: type) type {
    return struct {
        private: ?*anyopaque = null,

        pub const ListNode: type = struct {
            next: ?*@This(),
            prev: ?*@This(),
            data: t,
        };

        const Private: type = struct {
            root: ?*ListNode,
            iterator: ?*ListNode,
            iterator_index: usize,
            eol: ?*ListNode,
            nodes: usize,
        };

        pub const ListErr: type = error{
            AllocatorErr,
            IndexOutBounds,
            NoNInitialized,
            EndOfIterator,
            NoNNodes,
            NoNNodeFound,
            IteratorEarlyReturn,
            HandlerForceExit,
            WithoutNodes,
            NothingToDeinit,
            FreeNodeError,
            FreeInternalError,
        };

        fn checkAllocator(comptime at: type) void {
            switch (@typeInfo(at)) {
                .pointer => {},
                else => @compileError(
                    \\ expect pointer to allocator
                ),
            }
        }

        fn findIndex(self: *@This(), index: usize) ListErr!*ListNode {
            const private_casted: *Private = @call(.always_inline, castPrivate, .{self.private.?});
            if (private_casted.eol == null) return ListErr.NoNInitialized;
            if (index >= private_casted.nodes) return ListErr.IndexOutBounds;
            var current = private_casted.root.?;
            for (0..index) |_| {
                current = current.next.?;
            }
            return current;
        }

        inline fn checkInit(self: *@This(), comptime ignore_root: bool) ListErr!void {
            if (self.private == null)
                return ListErr.NoNInitialized;
            if (!ignore_root and castPrivate(self.private.?).root == null)
                return ListErr.WithoutNodes;
        }

        inline fn castPrivate(private: *anyopaque) *Private {
            return @ptrCast(@alignCast(private));
        }

        pub fn isInitialized(self: *@This()) bool {
            return self.private != null or self.howManyNodes() != 0;
        }

        /// * init the list (use whenever the node quantity is 0)
        pub fn init(self: *@This(), allocator: anytype) ListErr!void {
            comptime checkAllocator(@TypeOf(allocator));
            if (self.private != null) return;
            self.private = &(allocator.alloc(Private, 1) catch return ListErr.AllocatorErr)[0];
            castPrivate(self.private.?).* = .{
                .root = null,
                .eol = null,
                .iterator = null,
                .iterator_index = 0,
                .nodes = 0,
            };
        }

        /// * deinit the list (free all nodes)
        pub fn deinit(self: *@This(), allocator: anytype) ListErr!void {
            comptime checkAllocator(@TypeOf(allocator));
            if (!self.isInitialized())
                return ListErr.NothingToDeinit;
            const private_casted: *Private = castPrivate(self.private.?);
            var current: ?*ListNode = private_casted.eol;
            while (current) |node| {
                const prev: ?*ListNode = node.prev;
                allocator.free(node) catch return ListErr.FreeNodeError;
                current = prev;
            }
            allocator.free(private_casted) catch return ListErr.FreeInternalError;
            self.private = null;
        }

        /// * add a new no to the end of the list
        pub fn pushInList(self: *@This(), allocator: anytype, data: t) ListErr!void {
            comptime checkAllocator(@TypeOf(allocator));
            try self.checkInit(true);
            const private_casted: *Private = castPrivate(self.private.?);
            r: {
                if (private_casted.eol == null) {
                    @branchHint(.unlikely);
                    private_casted.* = .{
                        .root = &(allocator.alloc(ListNode, 1) catch return ListErr.AllocatorErr)[0],
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
                private_casted.eol.?.next = &(allocator.alloc(ListNode, 1) catch return ListErr.AllocatorErr)[0];
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
        pub fn dropOnList(self: *@This(), index: usize, allocator: anytype) ListErr!void {
            comptime checkAllocator(@TypeOf(allocator));
            try self.checkInit(true);
            const private_casted: *Private = castPrivate(self.private.?);
            if (private_casted.root == null) return ListErr.NoNNodes;
            var current: ?*ListNode = try @call(.never_inline, findIndex, .{ self, index });
            if (current.?.prev != null) {
                current.?.prev.?.next = current.?.next;
            }
            if (current == private_casted.root) {
                private_casted.root = current.?.next;
            }
            if (private_casted.iterator == current) {
                private_casted.iterator = current.?.next;
            }
            const slice: []ListNode = @as([*]ListNode, @ptrCast(current.?))[0..1];
            allocator.free(slice) catch {
                @branchHint(.unlikely);
                if (current.?.prev != null) {
                    @branchHint(.unlikely);
                    current.?.prev.?.next = current;
                }
                return ListErr.AllocatorErr;
            };
            private_casted.nodes -= 1;
        }

        /// * places it on an existing index, if it is a new index, it returns an error.
        ///     - to create a new index use pushInList
        pub fn putInIndex(self: *@This(), index: usize, data: t, allocator: anytype) ListErr!void {
            comptime checkAllocator(@TypeOf(allocator));
            try self.checkInit(true);
            const private_casted: *Private = castPrivate(self.private.?);
            const node_found: *ListNode = try @call(.never_inline, findIndex, .{ self, index });
            const new_node: *ListNode = &(allocator.alloc(ListNode, 1) catch return ListErr.AllocatorErr)[0];
            new_node.* = .{
                .next = null,
                .prev = null,
                .data = data,
            };
            r: {
                if (private_casted.root.? == node_found) {
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
        pub fn accessByIndex(self: *@This(), index: usize) ListErr!t {
            return (@call(.always_inline, findIndex, .{ self, index }) catch |err| return err).data;
        }

        /// * returns the current index of the iterator, with each call the
        /// iterator pointer moves to the next node
        pub fn iterator(self: *@This()) ListErr!t {
            try self.checkInit(true);
            const private_casted: *Private = castPrivate(self.private.?);
            if (private_casted.eol == null) return ListErr.NoNInitialized;
            if (private_casted.iterator == null) {
                private_casted.iterator = private_casted.root.?;
                private_casted.iterator_index = 0;
                return ListErr.EndOfIterator;
            }
            const current_iterator: *ListNode = private_casted.iterator.?;
            private_casted.iterator = private_casted.iterator.?.next;
            private_casted.iterator_index += 1;
            return current_iterator.data;
        }

        /// * returns the index where the iterator is pointing
        pub fn iteratorIndex(self: *@This()) ListErr!usize {
            return if (self.checkInit(false)) |_| castPrivate(self.private.?).iterator_index else |err| return err;
        }

        /// * iterator based on a handler
        ///     - If the handler returns an error, the iterator
        ///     continues until EndOfIterator
        ///     -  If it does not return an error, iterator
        ///     returns what is stored in the current node
        ///     - any is used as a parameter for the handler
        pub fn iteratorHandler(self: *@This(), any: anytype, comptime handler: *const fn (t, @TypeOf(any)) anyerror!void) ListErr!t {
            try self.checkInit(false);
            try self.iteratorReset();
            while (self.iterator()) |node_data| {
                @call(.never_inline, handler, .{ node_data, any }) catch |err| switch (err) {
                    error.ForceExit => return ListErr.HandlerForceExit,
                    else => continue,
                };
                return node_data;
            } else |err| {
                return err;
            }
        }

        /// * reset the iterator pointer to the first index
        pub fn iteratorReset(self: *@This()) ListErr!void {
            try self.checkInit(true);
            castPrivate(self.private.?).iterator = castPrivate(self.private.?).root;
            castPrivate(self.private.?).iterator_index = 0;
        }

        // * takes the value of the last index in the list
        pub fn lastIndex(self: *@This()) ListErr!usize {
            return if (self.checkInit(false)) |_| castPrivate(self.private.?).*.nodes - 1 else |err| return err;
        }

        // * gets the number of nodes in the list
        pub fn howManyNodes(self: *@This()) usize {
            return if (self.checkInit(true)) |_| castPrivate(self.private.?).nodes else |_| 0;
        }
    };
}
