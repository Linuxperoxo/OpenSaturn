// ┌───────────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: SinglyLinkedList.zig  │
// │            Author: Linuxperoxo                        │
// └───────────────────────────────────────────────────────┘

const SinglyLinkedList: type = @This();

first: ?*Node = null,
elems: usize = 0,

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

pub fn accessIndex(self: *const SinglyLinkedList, index: usize) ?*Node {
    if(index >= self.elems) return null;

    var it: ?*Node = self.first;
    var i: usize = 0;

    while(it) |node| : ({ it = node.next; i += 1; }) {
        if(i == index) return node;
    }

    return null;
}

pub fn append(self: *SinglyLinkedList, new_node: *Node) void {
    new_node.next = null;

    const first_node: *Node = self.first orelse {
        self.first = new_node;
        self.elems += 1;
        return;
    };

    first_node.findLast().next = new_node;
    self.elems += 1;
}

pub fn prepend(self: *SinglyLinkedList, new_node: *Node) void {
    new_node.next = self.first;
    self.first = new_node;
    self.elems += 1;
}

pub fn condDrop(self: *SinglyLinkedList, context: anytype, handler: fn(@TypeOf(context), *Node) callconv(.@"inline") bool) ?*Node {
    var it: ?*Node = self.first;

    while(it) |node| : (it = node.next) {
        if(handler(context, node)) {
            node.removeAfter();
            self.elems -= 1;
            return node;
        }
    }

    return null;
}

pub fn condFind(self: *SinglyLinkedList, context: anytype, handler: fn(@TypeOf(context), *Node) callconv(.@"inline") bool) ?*Node {
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
        self.elems -= 1;
    }
}

pub fn popFirst(self: *SinglyLinkedList) ?*Node {
    const first: *Node = self.first orelse return null;
    self.first = first.next;
    self.elems -= 1;
    return first;
}

test "basics" {
    const T: type = struct {
        data: u64,
        node: SinglyLinkedList.Node = .{},
    };

    var list: SinglyLinkedList = .{};

    var d0: T = .{ .data = 0 };
    var d1: T = .{ .data = 1 };
    var d2: T = .{ .data = 2 };
    var d3: T = .{ .data = 3 };
    var d4: T = .{ .data = 4 };

    list.append(&d0.node); // [ 0 ]
    list.append(&d1.node); // [ 0, 1 ]
    list.append(&d2.node); // [ 0, 1, 2 ]
    list.append(&d3.node); // [ 0, 1, 2, 3 ]

    if(list.elems != 4) return error.TotalOfElemsUnexpected;

    var expected_sequence = [_]u64 {
        0, 1, 2, 3
    };

    for(expected_sequence, 0..) |sequence, i| {
        if(list.accessIndex(i).?.containerOf(T).data != sequence)
            return error.ListOrderError;
    }

    _ = list.popFirst();
    _ = list.popFirst();
    _ = list.popFirst();
    _ = list.popFirst();

    list.prepend(&d0.node); // [ 0 ]
    list.prepend(&d1.node); // [ 1, 0 ]
    list.prepend(&d2.node); // [ 2, 1, 0 ]
    list.prepend(&d3.node); // [ 3, 2, 1, 0 ]

    expected_sequence = [_]u64 {
        3, 2, 1, 0
    };

    for(0..2) |_| {
        for(expected_sequence, 0..) |sequence, i| {
            if(list.accessIndex(i).?.containerOf(T).data != sequence)
                return error.ListOrderError;
        }

        list.remove(list.accessIndex(0).?); // [ 2, 1, 0 ]
        list.prepend(&d4.node); // [ 4, 2, 1, 0 ]

        expected_sequence = [_]u64 {
            4, 2, 1, 0
        };
    }
}
