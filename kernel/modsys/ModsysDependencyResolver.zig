// ┌───────────────────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ModsysDependencyResolver.zig  │
// │                     Author: Linuxperoxo                       │
// └───────────────────────────────────────────────────────────────┘

const architecture: type = @import("root").__SaturnArchImpl__.arch;
const interfaces: type = @import("root").interfaces;
const lib: type = @import("root").lib;
const memory: type = lib.kernel.mem;

const ModsysDepResolver: type = @This();
const DependencyGraph: type = lib.kernel.DependencyGraph;
const Allocator: type = lib.kernel.allocation.Allocator;
const Module: type = interfaces.module.Module;

modulesToResolve: []*const Module,
dependencyGraph: DependencyGraph,

pub inline fn init(modulesToResolve: []*const Module) ModsysDepResolver {
    return ModsysDepResolver {
        .modulesToResolve = modulesToResolve,
        .dependencyGraph = DependencyGraph.init(),
    };
}

pub inline fn resolver(dependencyResolver: *ModsysDepResolver, allocator: Allocator) (Allocator.Error || DependencyGraph.DependencyGraphError)![]*const Module {
    try dependencyResolver.buildModuleDependencyGraph(allocator);
    return dependencyResolver.modulesInDependencyOrder(allocator);
}

// -----------------------------------------------------------------------------------

noinline fn buildModuleDependencyGraph(dependencyResolver: *ModsysDepResolver, allocator: Allocator) (Allocator.Error || DependencyGraph.DependencyGraphError)!void {
    for(dependencyResolver.modulesToResolve) |moduleToAddToDependencyGraph| {
        try dependencyResolver.dependencyGraph.addVertex(moduleToAddToDependencyGraph, allocator);
    }

    for(dependencyResolver.modulesToResolve) |moduleWithDependencies| {
        if(moduleWithDependencies.mod.deps != null) {
            for(moduleWithDependencies.mod.deps.?) |dependencyName| {
                var graphVertexIterator = dependencyResolver.dependencyGraph.vertexList.first;
                while(graphVertexIterator) |graphVertexNode| : (graphVertexIterator = graphVertexNode.next) {
                    const dependencyModule: *Module = graphVertexNode.containerOf(DependencyGraph.GraphVertex).data;
                    if(memory.eql(dependencyName, dependencyModule.mod.name, .{})) {
                        try dependencyResolver.dependencyGraph.addDependency(
                            moduleWithDependencies,
                            graphVertexNode.containerOf(DependencyGraph.GraphVertex).data,
                            allocator
                        );
                        break;
                    }
                }
            }
        }
    }
}

inline fn modulesInDependencyOrder(dependencyResolver: *const ModsysDepResolver, allocator: Allocator) Allocator.Error![]*const Module {
    return @alignCast(@ptrCast(try dependencyResolver.dependencyGraph.sliceInDependencyOrder(allocator)));
}
