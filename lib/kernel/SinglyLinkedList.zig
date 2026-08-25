// ┌───────────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: SinglyLinkedList.zig  │
// │            Author: Linuxperoxo                        │
// └───────────────────────────────────────────────────────┘

const SinglyLinkedList: type = @This();

first: ?*Node = null,

pub const Node: type = struct {
    next: ?*Node = null,

    pub fn insertAfter(self: *Node, new_node: *Node) void {
        new_node.next = self.next;
        self.next = new_node;
    }

   pub fn removeAfter(self: *Node) ?*Node {
       const next_node: *Node = self.next orelse return null;
       self.next = next_node.next;
       return next_node;
   }

   pub fn findLast(self: *Node) *Node {
       var it: *Node = self;

       while(true) {
           it = it.next orelse return it;
       }
   }

   pub fn containerOf(self: *Node, comptime T: type) *T {
       return @fieldParentPtr("node", self);
   }
};

pub fn append(self: *SinglyLinkedList, new_node: *Node) void {
    new_node.next = null;

    const first_node: *Node = self.first orelse {
        self.first = new_node;
        return;
    };

    first_node.findLast().next = new_node;
}

pub fn prepend(self: *SinglyLinkedList, new_node: *Node) void {
    new_node.next = self.first;
    self.first = new_node;
}

pub fn conditionalFind(self: *SinglyLinkedList, context: anytype, handler: fn(@TypeOf(context), *Node) callconv(.@"inline") bool) ?*Node {
    var it: ?*Node = self.first;

    while(it) |node| : (it = node.next) {
        if(handler(context, node))
            return node;
    }

    return null;
}

pub fn remove(self: *SinglyLinkedList, node: *Node) void {
    if (self.first == node) {
        self.first = node.next;
    } else {
        var current_elm: *Node = self.first.?;

        while (current_elm.next != node) :
            (current_elm = current_elm.next.?) {}

        current_elm.next = node.next;
    }
}

pub fn popFirst(list: *SinglyLinkedList) ?*Node {
    const first: *Node = list.first orelse return null;
    list.first = first.next;
    return first;
}
