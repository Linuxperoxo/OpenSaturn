// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: deps.zig    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const modules: type = @import("modules.zig");
const types: type = @import("types.zig");
const mem: type = @import("root").lib.utils.mem;

fn add_vertex_init(
    comptime vertex: *types.Vertex_T,
    comptime init_order: *[modules.saturn_modules.len]*const interfaces.module.ModuleDescription_T,
    comptime init_order_index: *usize,
) void {
    comptime {
        if(!vertex.flags.done) {
            vertex.flags.done = true;
            init_order[init_order_index.*] = vertex.module.?;
            init_order_index.* += 1;
        }
    }
}

fn vertex_recursive(
    comptime current_vertex: *types.Vertex_T,
    comptime init_order: *[modules.saturn_modules.len]*const interfaces.module.ModuleDescription_T,
    comptime init_order_index: *usize,
    comptime root_vertex: *types.Vertex_T,
) void {
    comptime {
        @setEvalBranchQuota(4294967295);
        if(current_vertex.flags.done) return;
        if(current_vertex.flags.any) {
            for(current_vertex.childs) |child| {
                if(child == null) continue;
                if(child.?.flags.done) continue;

                if(child.? == root_vertex)
                    @compileError("Modsys Error: circular dependency \"" ++ current_vertex.module.?.mod.name ++ "\" with \"" ++ root_vertex.module.?.mod.name ++ "\"");

                if(child.?.flags.any)
                    vertex_recursive(child.?, init_order, init_order_index, root_vertex);

                if(!child.?.flags.done)
                    add_vertex_init(child.?, init_order, init_order_index);
            }
        }
    }
    add_vertex_init(current_vertex, init_order, init_order_index);
}

pub fn resolve_dependencies() [modules.saturn_modules.len]*const interfaces.module.ModuleDescription_T {
    const max_childs = @typeInfo(@FieldType(types.Vertex_T, "childs")).array.len;

    var graph_vertex_pool = [_]types.Vertex_T {
        types.Vertex_T {
            .module = null,
            .childs = [_]?*types.Vertex_T { null } ** max_childs,
            .flags = .{
                .done = false,
                .any = false,
            },
        },
    } ** modules.saturn_modules.len;

    // dando uma vertice para cada modulo
    for(0..modules.saturn_modules.len) |i|
        graph_vertex_pool[i].module = &modules.saturn_modules[i];

    // montando grafo
    for(&graph_vertex_pool, 0..) |*vertex, j| {
        var i: usize = 0;
        if(vertex.module.?.mod.deps == null or vertex.module.?.mod.deps.?.len == 0) continue;
        if(vertex.module.?.mod.deps.?.len > max_childs)
            @compileError("Modsys Error: " ++ vertex.module.?.mod.name ++ "deps.len > 16");

        graph_vertex_pool[j].flags.any = true;

        for(vertex.module.?.mod.deps.?) |dep| {
            vertex.childs[i] = r: {
                for(&graph_vertex_pool) |*current_dep_vertex| {
                    if(mem.eql(current_dep_vertex.module.?.mod.name, dep, .{ .case = true } ))
                        break :r current_dep_vertex;
                }
                @compileError("Modsys Error: \"" ++ dep ++ "\" dependency of \"" ++ vertex.module.?.mod.name ++ "\" does not exist");
            };
            i += 1;
        }
    }

    var init_order: [modules.saturn_modules.len]*const interfaces.module.ModuleDescription_T = undefined;
    var init_order_index: usize = 0;
    for(&graph_vertex_pool) |*vertex| {
        vertex_recursive(vertex, &init_order, &init_order_index, vertex);
    }
    return init_order;
}
