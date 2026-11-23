// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: Modsys.zig  │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const lib: type = @import("root").lib;
const mem: type = lib.kernel.mem;

const Modsys: type = @This();
const DependencyGraph: type = lib.kernel.DependencyGraph;
const Allocator: type = lib.kernel.allocation.Allocator;
const ModuleDescription: type = interfaces.module.ModuleDescription;

modules: []ModuleDescription,
graph: DependencyGraph,

pub fn init(modules: []const interfaces.module.ModuleDescription) Modsys {
    return Modsys {
        .modules = modules,
        .graph = DependencyGraph.init(),
    };
}

pub fn makeModulesGraph(self: *Modsys, allocator: Allocator) (Allocator.Error || DependencyGraph.DependencyGraphError)!void {
    for(self.modules) |*module| {
        try self.graph.addVertex(module, allocator);
    }

    for(self.modules) |*module| {
        if(module.mod.deps != null) {
            for(module.mod.deps.?) |dep| {
                var it = self.graph.vertexList.first;
                while(it) |node| : (it = node.next) {
                    const depModuleDesc: *ModuleDescription = node.containerOf(DependencyGraph.GraphVertex).data;
                    if(mem.eql(dep, depModuleDesc.mod.name, .{})) {
                        try self.graph.addDependency(
                            module,
                            node.containerOf(DependencyGraph.GraphVertex).data,
                            allocator
                        );
                        break;
                    }
                }
            }
        }
    }
}
