// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: deps.zig    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

// esse sistema de dependencia nao foi feito para ser
// o melhor e mais complexo de todos os tempos, apenas
// fiz ele pensando no meu proprio jeito de resolver
// dependencias sem usar algoritmos ja feitos. Esse
// algoritmo e pensando exclusivamente para o kernel,
// um modulo ter mais que 5 dependencias e extremamente
// improvavel

const modules: type = @import("root").modules;
const interfaces: type = @import("root").interfaces;
const kernel: type = @import("root").kernel;
const modsys: type = @import("modsys.zig");
const types: type = @import("types.zig");

const Node_T: type = types.Node_T;
const Direct_T: type = types.Direct_T;

const count_with_out_deps = t: {
    var count: usize = 0;
    for(modsys.saturn_modules) |module| {
        count += if(module.deps == null) 1 else 0;
    }
    break :t count;
};

const count_with_deps = t: {
    var count: usize = 0;
    for(modsys.saturn_modules) |module| {
        count += if(module.deps != null) 1 else 0;
    }
    break :t count;
};

fn find_module_node(
    comptime search_root: *const Node_T,
    comptime name: []const u8,
    comptime direct: Direct_T,
) anyerror!*Node_T {
    var current: ?*Node_T = if(direct == .left) search_root.prev else search_root.next;
    while(current != null) : (
        current = if(direct == .left) current.?.prev else current.?.next
    ) {
        if(kernel.utils.mem.eql(current.?.module.?.name, name, .{})) {
            return current.?;
        }
    }
    return error.NoNFound;
}

fn find_module(comptime name: []const u8) anyerror!interfaces.module.ModuleDescription_T {
    for(modsys.saturn_modules) |module| {
        if(kernel.utils.mem.eql(module.name, name, .{})) {
            return module;
        }
    }
    return error.NoNfound;
}

fn make_module_list(
    comptime pull: *[count_with_deps]Node_T,
    comptime modules_with_deps: [count_with_deps]interfaces.module.ModuleDescription_T,
) struct { *Node_T, [count_with_deps]*Node_T } {
    var node_pointers: [count_with_deps]*Node_T = undefined;
    var current: *Node_T = &pull[0];
    var prev: ?*Node_T = null;
    for(0..count_with_deps) |i| {
        current.* = .{
            .next = if(i + 1 < count_with_deps) &pull[i + 1] else null,
            .prev = prev,
            .module = modules_with_deps[i],
            .flags = .{
                .fixed = 0,
            },
        };
        node_pointers[i] = current;
        prev = current;
        if(current.next != null)
            current = current.next.?;
    }
    return .{
        &pull[0],
        node_pointers,
    };
}

fn @"circular_dep?"(
    comptime dep: *const interfaces.module.ModuleDescription_T,
    comptime mod: *const interfaces.module.ModuleDescription_T,
) bool {
    // dependencia circular de apenas 1 nivel e suficiente por enquanto
    // TODO: colocar mais um nivel
    for(dep.deps.?) |dep_of_dep| {
        if(kernel.utils.mem.eql(dep_of_dep, mod.name, .{})) {
            return true;
        }
    }
    return false;
}

fn make_module_array(comptime root_node: *Node_T) [count_with_deps]interfaces.module.ModuleDescription_T {
    var resolved_modules: [count_with_deps]interfaces.module.ModuleDescription_T = undefined;
    var current: ?*Node_T = root_node;
    for(0..resolved_modules.len) |i| {
        resolved_modules[i] = current.?.module.?;
        current = current.?.next;
    }
    return resolved_modules;
}

pub fn resolve_dependencies()
    [count_with_out_deps + count_with_deps]interfaces.module.ModuleDescription_T {
    // sem duvidas fazer isso ser resolvido por completo no comptime
    // pode deixar o codigo um pouco massivo, devemos evitar ao maximo
    // usar ponteiros, sempre usar array bruto. Algumas coisas nesse codigo
    // sao do jeito que sao justamente por causa do comptime
    const modules_with_out_deps = r: {
        var mods: [count_with_out_deps]interfaces.module.ModuleDescription_T = undefined;
        var index: usize = 0;
        for(modsys.saturn_modules) |module| {
            if(module.deps == null) {
                mods[index] = module;
                index += 1;
            }
        }
        break :r mods;
    };
    // nada para resolver
    if(count_with_deps == 0) return modules_with_out_deps;
    const modules_with_deps = r: {
        var mods: [count_with_deps]interfaces.module.ModuleDescription_T = undefined;
        var index: usize = 0;
        for(modsys.saturn_modules) |module| {
            if(module.deps != null) {
                mods[index] = module;
                index += 1;
            }
        }
        break :r mods;
    };
    var node_pull: [count_with_deps]Node_T = undefined;
    var root_node: ?*Node_T, const node_pointers = make_module_list(
        &node_pull,
        modules_with_deps
    );
    for(node_pointers) |node| {
        for(node.module.?.deps.?) |dep_name| {
            // procuramos a dependencia, e vemos se a dependencia tem dependencia
            const module_found = find_module(dep_name) catch {
                @compileError(
                    "modsys: " ++
                    dep_name ++
                    " dependence of the " ++
                    node.module.?.name ++
                    " does not exist or has been disabled"
                );
            };
            // caso a dependencia nao tenha dependencia, nao precisamos resolver ela,
            // vamos para o proximo
            if(module_found.deps == null) continue;
            if(@"circular_dep?"(&module_found, &node.module.?)) {
                @compileError(
                    "modsys: circular dependence between " ++
                    node.module.?.name ++
                    " and " ++
                    module_found.name
                );
            }
            const direct, const dep_node = t: {
                // caso tenha, procuramos o node daquela dependencia
                if(find_module_node(node, dep_name, .right)) |found| {
                    break :t .{
                        Direct_T.right,
                        found,
                    };
                } else |_| {}
                if(find_module_node(node, dep_name, .left)) |found| {
                    break :t .{
                        Direct_T.left,
                        found,
                    };
                } else |_| {
                    @compileError(
                        "modsys: dependence "
                        ++ dep_name ++
                        " of module "
                        ++ node.module.?.name ++
                        " not found"
                    );
                }
            };
            // apenas para evitar quebra na lista
            if((dep_node.next != null and dep_node.next == node)
                // se encontrou a esquerda, ja esta resolvido, nao precisa fazer nada
                or direct == .left) continue;
            // aqui caso a dependencia nao foi fixada, colocamos ela na
            // frente do modulo
            if(dep_node.flags.fixed == 0) {
                if(dep_node == root_node) {
                    root_node = dep_node.next;
                    if(root_node != null) {
                        root_node.?.prev = null;
                    }
                } else {
                    dep_node.prev.?.next = dep_node.next;
                    if(dep_node.next != null) {
                        dep_node.next.?.prev = dep_node.prev;
                    }
                    if(node.prev != null) {
                        node.prev.?.next = dep_node;
                    }
                    dep_node.prev = node.prev;
                    if(dep_node.prev == null) {
                        root_node = dep_node;
                    }
                    node.prev = dep_node;
                    dep_node.next = node;
                }
                // fixamos ambos
                node.flags.fixed = 1;
                dep_node.flags.fixed = 1;
                continue;
            }
            // ja aqui, caso a dependencia foi fixada, jogamos o modulo para
            // tras da dependencia
            if(node == root_node) {
                root_node = node.next;
                if(root_node != null) {
                    root_node.?.prev = null;
                }
            } else {
                node.prev.?.next = node.next;
                if(node.next != null) {
                    node.next.?.prev = node.prev;
                }
                node.next = dep_node.next;
                dep_node.next = node;
                node.prev = dep_node;
                if(node.next != null) {
                    node.next.?.prev = node;
                }
            }
            // fixamos ambos
            node.flags.fixed = 1;
            dep_node.flags.fixed = 1;
        }
    }
    return modules_with_out_deps ++ make_module_array(root_node.?);
}
