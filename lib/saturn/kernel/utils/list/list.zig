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
            interator: ?*ListNode_T,
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

        pub fn cast_private(private: *anyopaque) *Private_T {
            return @alignCast(@ptrCast(private));
        }

        pub fn init(self: *@This(), allocator: anytype) ListErr_T!void {
            comptime check_allocator(@TypeOf(allocator));
            self.private = &(allocator.alloc(Private_T, 1) catch return ListErr_T.AllocatorErr)[0];
            const private_casted: *Private_T = @call(.always_inline, cast_private, .{
                self.private.?
            });
            private_casted.root = null;
            private_casted.nodes = 0;
            private_casted.eol = null;
        }

        pub fn push_in_list(self: *@This(), allocator: anytype, data: T) ListErr_T!void {
            comptime check_allocator(@TypeOf(allocator));
            if(self.private == null) return ListErr_T.NoNInitialized;
            const private_casted: *Private_T = @call(.always_inline, cast_private, .{
                self.private.?
            });
            r: {
                if(private_casted.eol == null) {
                    @branchHint(.unlikely);
                    private_casted.root = &(allocator.alloc(ListNode_T, 1) catch return ListErr_T.AllocatorErr)[0];
                    private_casted.root.?.data = data;
                    private_casted.root.?.next = null;
                    private_casted.root.?.prev = null;
                    private_casted.eol = private_casted.root;
                    private_casted.interator = private_casted.root;
                    break :r {};
                }
                private_casted.eol.?.next = &(allocator.alloc(ListNode_T, 1) catch return ListErr_T.AllocatorErr)[0];
                private_casted.eol.?.next.?.data = data;
                private_casted.eol.?.next.?.prev = private_casted.eol;
                private_casted.eol.?.next.?.next = null;
                private_casted.eol = private_casted.eol.?.next;
            }
            private_casted.nodes += 1;
        }

        pub fn drop_on_list(self: *@This(), index: usize, allocator: anytype) ListErr_T!void {
            comptime check_allocator(@TypeOf(allocator));
            if(self.private == null) return ListErr_T.NoNInitialized;
            const private_casted: *Private_T = @call(.always_inline, cast_private, .{
                self.private.?
            });
            if(private_casted.root == null) return ListErr_T.NoNNodes;
            var current: ?*ListNode_T = try @call(.always_inline, find_index, .{
                self, index
            });
            if(current.?.prev != null) {
                current.?.prev.?.next = current.?.next;
            }
            if(current == private_casted.root) {
                private_casted.root = current.?.next;
            }
            if(private_casted.interator == current) {
                private_casted.interator = current.?.next;
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

        pub fn put_in_index(self: *@This(), index: usize) ListErr_T!void {
            const node = try @call(.always_inline, find_index, .{
                self, index
            });
            const private_casted: *Private_T = @call(.always_inline, cast_private, .{
                self.private.?
            });
            if(node == )
        }

        pub fn access_by_index(self: *@This(), index: usize) ListErr_T!T {
            return (@call(.always_inline, find_index, .{
                self, index
            }) catch |err| return err).data;
        }

        pub fn iterator(self: *@This()) ListErr_T!T {
            if(self.private == null) return ListErr_T.NoNInitialized;
            const private_casted: *Private_T = @call(.always_inline, cast_private, .{
                self.private.?
            });
            if(private_casted.eol == null) return ListErr_T.NoNInitialized;
            if(private_casted.interator == null) {
                private_casted.interator = private_casted.root.?;
                return ListErr_T.EndOfIterator;
            }
            const current_interator: *ListNode_T = private_casted.interator.?;
            private_casted.interator = private_casted.interator.?.next;
            return current_interator.data;
        }

        pub fn iterator_reset(self: *@This()) ListErr_T!void {
            if(self.private == null) return ListErr_T.NoNInitialized;
            const private_casted: *Private_T = @call(.always_inline, cast_private, .{
                self.private.?
            });
            private_casted.interator = private_casted.root;
        }
    };
}
