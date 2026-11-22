// ┌──────────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: DependencyGraph.zig  │
// │                 Author: Linuxperoxo                  │
// └──────────────────────────────────────────────────────┘

const SinglyLinkedList: type = @import("SinglyLinkedList.zig");
const Allocator: type = @import("alloc/Allocator.zig");
const Stack: type = @import("stack.zig").Stack(*GraphVertex);
const DependencyGraph: type = @This();
const GraphVertex: type = struct {
    data: *anyopaque,
    open: bool,
    visiting: bool,
    node: SinglyLinkedList.Node = SinglyLinkedList.Node.init(),
    edges: SinglyLinkedList = SinglyLinkedList.init(),
};
const GraphEdge: type = struct {
    target: *GraphVertex,
    node: SinglyLinkedList.Node = SinglyLinkedList.Node.init(),
};

pub const DependencyGraphError: type = error {
    DependentNotFound,
    DependencyNotFound,
    CircularDependency,
};

vertexList: SinglyLinkedList,
stack: Stack,

inline fn findVertexByData(self: *const DependencyGraph, data: *anyopaque) ?*GraphVertex {
    var it = self.vertexList.first;
    while(it) |node| : (it = it.?.next) {
        const vertex = node.containerOf(GraphVertex);
        if(vertex.data == data)
            return vertex;
    }
    return null;
}

pub fn init() DependencyGraph {
    return DependencyGraph {
        .vertexList = SinglyLinkedList.init(),
        .stack = Stack.init(),
    };
}

pub fn addVertex(self: *DependencyGraph, data: *anyopaque, allocator: Allocator) Allocator.Err!void {
    if(self.findVertexByData(data)) |_|
        return;

    const vertex: *GraphVertex = try allocator.create(GraphVertex);
    vertex.* = .{
        .data = data,
        .open = true,
        .visiting = false,
        .node = .{},
        .edges = SinglyLinkedList.init(),
    };
    self.vertexList.prepend(&vertex.node);
}

pub fn addDependency(self: *DependencyGraph, dependentData: *anyopaque, dependencyData: *anyopaque, allocator: Allocator) (DependencyGraphError || Allocator.Err)!void {
    const dependentVertex: *GraphVertex = self.findVertexByData(dependentData) orelse return DependencyGraphError.DependentNotFound;
    const dependencyVertex: *GraphVertex = self.findVertexByData(dependencyData) orelse return DependencyGraphError.DependencyNotFound;

    const edge: *GraphEdge = try allocator.create(GraphEdge);
    edge.* = .{
        .target = dependencyVertex,
        .node = SinglyLinkedList.Node.init(),
    };
    dependentVertex.edges.prepend(&edge.node);
}

pub fn sliceInDependencyOrder(self: *DependencyGraph, allocator: Allocator) (DependencyGraphError || Allocator.Err)![]*anyopaque {
    const sequenceSlice: []*anyopaque = try allocator.alloc(*anyopaque, self.vertexList.elems);
    var sequenceSliceIndex: usize = 0;

    var vertexIt = self.vertexList.first;
    while(vertexIt) |node| : (vertexIt = vertexIt.?.next) {
        var currentVertex: ?*GraphVertex = node.containerOf(GraphVertex);
        while(currentVertex != null) {
            if(!currentVertex.?.open) {
                currentVertex = self.stack.pop();
                continue;
            }

            r: {
                var edgeIt = currentVertex.?.edges.first;
                while(edgeIt) |edge| : (edgeIt = edgeIt.?.next) {
                    const vertex = edge.containerOf(GraphEdge).target;

                    if(vertex.visiting)
                        return DependencyGraphError.CircularDependency;

                    if(!vertex.open) continue;

                    try self.stack.push(currentVertex.?, allocator);

                    currentVertex.?.visiting = true;
                    currentVertex = vertex;

                    break :r {};
                }

                sequenceSlice[sequenceSliceIndex] = currentVertex.?.data;
                currentVertex.?.open = false;
                currentVertex.?.visiting = false;
                sequenceSliceIndex += 1;
                currentVertex = self.stack.pop();
            }
        }
    }

    return sequenceSlice;
}
