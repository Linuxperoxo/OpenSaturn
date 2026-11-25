// ┌───────────────────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ModsysMenuconfigResolver.zig  │
// │                     Author: Linuxperoxo                       │
// └───────────────────────────────────────────────────────────────┘

const arch: type = @import("root").__SaturnArchImpl__.arch;
const config: type = @import("root").config;
const menuconfig: type = @import("root").menuconfig;
const lib: type = @import("root").lib;
const interfaces: type = @import("root").interfaces;
const builtin: type = @import("std").builtin;

const ModsysMenuconfigResolver: type = @This();
const Allocator: type = lib.kernel.allocation.Allocator;
const Module: type = interfaces.module.Module;
const SinglyLinkedList: type = lib.kernel.SinglyLinkedList;
const MenuconfigStruct: type = createMenuconfigStructType(menuconfig.__SaturnModulesMenuconfig__);
const ApprovedModuleNode: type = @import("ApprovedModuleNode.zig");

modules: []Module,

pub inline fn init(availableModules: []Module) ModsysMenuconfigResolver {
    return ModsysMenuconfigResolver {
        .modules = availableModules,
    };
}

pub inline fn resolver(self: *const ModsysMenuconfigResolver, allocator: Allocator) Allocator.Error![]*const Module {
    const resolvedMenuconfig: MenuconfigStruct = resolveMenuconfigWithArchOverrider();
    const availableModules: []Module = self.modules;
    return obtainModulesWithMenuconfigValue(
        availableModules,
        resolvedMenuconfig,
        'y',
        allocator
    );
}

// ---------------------------------------------------------------------------------------------------------------------

inline fn createMenuconfigStructType(modulesMenuconfigEntries: @TypeOf(menuconfig.__SaturnModulesMenuconfig__)) type {
    if(modulesMenuconfigEntries.len == 0) return void;

    var menuconfigStructTypeFields: [modulesMenuconfigEntries.len]builtin.Type.StructField = undefined;
    for(&modulesMenuconfigEntries, &menuconfigStructTypeFields) |*moduleMenuconfigEntry, *menuconfigStructTypeField| {
        menuconfigStructTypeField = .{
            .name = @ptrCast(moduleMenuconfigEntry.module),
            .type = u8,
            .alignment = 1,
            .is_comptime = true,
            .default_value_ptr = @ptrCast(&moduleMenuconfigEntry.value),
        };
    }

    return @Type(.{
        .@"struct" = .{
            .fields = &menuconfigStructTypeFields,
            .decls = &[_]builtin.Type.Declaration {},
            .layout = .auto,
            .is_tuple = false,
        },
    });
}

inline fn resolveMenuconfigWithArchOverrider() MenuconfigStruct {
    var resolvedMenuconfig: MenuconfigStruct = .{};
    if(config.modules.options.force_module_arch_overrider and arch.__SaturnArchDescription__.overrider.modules != null) {
        for(arch.__SaturnArchDescription__.overrider.modules) |architectureModuleOverrider| {
            if(@hasField(@TypeOf(resolvedMenuconfig), architectureModuleOverrider.module))
                @field(resolvedMenuconfig, architectureModuleOverrider.module) = architectureModuleOverrider.value;
        }
    }
}

inline fn obtainModulesWithMenuconfigValue(availableModules: []Module, resolvedMenuconfig: MenuconfigStruct, expectedMenuconfigValue: u8, allocator: Allocator) Allocator.Error![]*const Module {
    var approvedModulesByMenuconfigList: SinglyLinkedList = SinglyLinkedList.init();
    for(availableModules) |*availableModule| {
        if(@hasField(@TypeOf(resolvedMenuconfig), availableModule.name)) {
            const moduleMenuconfigValue: u8 = @field(resolvedMenuconfig, availableModule.name);
            switch(moduleMenuconfigValue) {
                'y', 'n' => {
                    if(moduleMenuconfigValue == expectedMenuconfigValue) {
                        const approvedModule: *ApprovedModuleNode = try allocator.create(ApprovedModuleNode);
                        approvedModule = .{
                            .module = availableModule,
                            .node = SinglyLinkedList.Node.init(),
                        };
                        approvedModulesByMenuconfigList.append(&approvedModule.node);
                    }
                },
                else => @compileError("[error] ModsysMenuconfigResolver: invalid menuconfig value for \"" ++ availableModule.name ++ "\""),
            }
        }
    }

    const resolvedModules: []*const Module = try allocator.alloc(*const Module, approvedModulesByMenuconfigList.elems);

    var it = approvedModulesByMenuconfigList.first;
    var currentIndex: usize = 0;
    while(it) |node| : ({ it = node.next; currentIndex += 1; })
        resolvedModules[currentIndex] = node.containerOf(ApprovedModuleNode).module;

    return resolvedModules;
}
