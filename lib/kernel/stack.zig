// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: stack.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Allocator: type = @import("Allocator.zig");
const SinglyLinkedList: type = @import("SinglyLinkedList.zig");

pub fn Stack(comptime T: type) type {
    return struct {
        const Self: type = @This();

        const StackNode: type = struct {
            data: T,
            node: SinglyLinkedList.Node,
        };

        list: SinglyLinkedList,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return Self {
                .list = .{},
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.deinit();
            self.list.first = null;
        }

        pub fn push(self: *Self, data: T) Allocator.Err!void {
            const stack_node: *StackNode = try self.allocator.create(StackNode);
            stack_node.data = data;
            self.list.prepend(&stack_node.node);
        }

        pub fn pop(self: *Self) ?T {
            const list_node: ?*SinglyLinkedList.Node = self.list.popFirst();

            if(list_node == null)
                return null;

            return list_node.?.containerOf(StackNode).data;
        }

        pub fn peek(self: *Self) ?T {
            const list_node: ?*SinglyLinkedList.Node = self.list.first;

            if(list_node == null)
                return null;

            return list_node.?.containerOf(StackNode).data;
        }

        pub fn size(self: *const Self) usize {
            return self.list.elems;
        }
    };
}
