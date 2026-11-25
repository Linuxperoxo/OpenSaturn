// ┌─────────────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ModsysArchResolver.zig  │
// │                  Author: Linuxperoxo                    │
// └─────────────────────────────────────────────────────────┘

const arch: type = @import("root").__SaturnArchImpl__.arch;
const lib: type = @import("root").lib;
const interfaces: type = @import("root").interfaces;

const ModsysArchResolver: type = @This();
const Allocator: type = lib.kernel.allocation.Allocator;
const Module: type = interfaces.module.Module;
const SinglyLinkedList: type = lib.kernel.SinglyLinkedList;
const ApprovedModuleNode: type = @import("ApprovedModuleNode.zig");

modules: []*const Module,

pub fn init(modulesToResolve: []*const Module) ModsysArchResolver {
    return ModsysArchResolver {
        .modules = modulesToResolve,
    };
}

pub fn resolver(self: *ModsysArchResolver, allocator: Allocator) Allocator.Error![]*const Module {
    var approvedModulesByArchList: SinglyLinkedList = SinglyLinkedList.init();
    for(self.modules) |module| {
        if(moduleSupportThisArch(module, arch.target)) {
            const approvedModule: *ApprovedModuleNode = try allocator.create(ApprovedModuleNode);
            approvedModule = .{
                .module = module,
                .node = SinglyLinkedList.Node.init(),
            };
            approvedModulesByArchList.append(&approvedModule.node);
        }
    }

    const resolvedModules: []*const Module = try allocator.alloc(*const Module, approvedModulesByArchList.elems);

    var it = approvedModulesByArchList.first;
    var currentIndex: usize = 0;
    while(it) |node| : ({ it = node.next; currentIndex += 1; })
        resolvedModules[currentIndex] = node.containerOf(ApprovedModuleNode).module;

    return resolvedModules;
}

// --------------------------------------------------------------------------------------------------

inline fn moduleSupportThisArch(module: *const Module, toFindtarget: interfaces.arch.Target) bool {
    for(module.targets) |moduleTarget| {
        if(moduleTarget == toFindtarget)
            return true;
    }
    return false;
}
