// ┌───────────────────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ModsysMenuconfigResolver.zig  │
// │                     Author: Linuxperoxo                       │
// └───────────────────────────────────────────────────────────────┘

const architecture: type = @import("root").__SaturnArchImpl__.arch;
const kernelConfig: type = @import("root").config;
const modulesMenuconfig: type = @import("root").menuconfig;
const lib: type = @import("root").lib;
const interfaces: type = @import("root").interfaces;
const builtin: type = @import("std").builtin;

const ModsysMenuconfigResolver: type = @This();
const Allocator: type = lib.kernel.allocation.Allocator;
const Module: type = interfaces.module.Module;
const SinglyLinkedList: type = lib.kernel.SinglyLinkedList;
const MenuconfigStruct: type = createMenuconfigStructType(modulesMenuconfig.__SaturnModulesMenuconfig__);

pub const AprovedModule: type = struct {
    module: *const Module,
    node: SinglyLinkedList.Node,
};

modules: []*const Module,

pub inline fn init(availableModules: []*const Module) ModsysMenuconfigResolver {
    return ModsysMenuconfigResolver {
        .modules = availableModules,
    };
}

pub inline fn resolver(resolverInstance: *const ModsysMenuconfigResolver, allocator: Allocator) Allocator.Error![]*const Module {
    const resolvedMenuconfig: MenuconfigStruct = resolveMenuconfigWithArchOverrider();
    const availableModules: []*const Module = resolverInstance.modules;
    return obtainModulesWithMenuconfigValue(
        availableModules,
        resolvedMenuconfig,
        allocator
    );
}

// ---------------------------------------------------------------------------------------------------------------------

inline fn createMenuconfigStructType(modulesMenuconfigEntries: @TypeOf(modulesMenuconfig.__SaturnModulesMenuconfig__)) type {
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
    if(kernelConfig.modules.options.force_module_arch_overrider and architecture.__SaturnArchDescription__.overrider.modules != null) {
        for(architecture.__SaturnArchDescription__.overrider.modules) |architectureModuleOverrider| {
            if(@hasField(@TypeOf(resolvedMenuconfig), architectureModuleOverrider.module))
                @field(resolvedMenuconfig, architectureModuleOverrider.module) = architectureModuleOverrider.value;
        }
    }
}

inline fn obtainModulesWithMenuconfigValue(availableModules: []*const Module, resolvedMenuconfig: MenuconfigStruct, expectedMenuconfigValue: u8, allocator: Allocator) Allocator.Error![]*const Module {
    var approvedModulesLinkedList: SinglyLinkedList = SinglyLinkedList.init();
    for(availableModules) |availableModule| {
        if(@hasField(@TypeOf(resolvedMenuconfig), availableModule.name)) {
            const moduleMenuconfigValue: u8 = @field(resolvedMenuconfig, availableModule.name);
            switch(moduleMenuconfigValue) {
                'y', 'n' => {
                    if(moduleMenuconfigValue == expectedMenuconfigValue) {
                        const approvedModuleEntry: *AprovedModule = try allocator.create(AprovedModule);
                        approvedModuleEntry = .{
                            .module = availableModule,
                            .node = SinglyLinkedList.Node.init(),
                        };
                        approvedModulesLinkedList.append(&approvedModuleEntry.node);
                    }
                },
                else => @compileError("[error] ModsysMenuconfigResolver: invalid menuconfig value for \"" ++ availableModule.name ++ "\""),
            }
        }
    }

    const resolvedModules: []*const Module = try allocator.alloc(*const Module, approvedModulesLinkedList.elems);

    var it = approvedModulesLinkedList.first;
    var currentIndex: usize = 0;
    while(it) |node| : ({ it = node.next; currentIndex += 1; })
        resolvedModules[currentIndex] = node.containerOf(AprovedModule).module;

    return resolvedModules;
}
