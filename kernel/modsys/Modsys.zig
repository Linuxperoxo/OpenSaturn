// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: Modsys.zig  │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const lib: type = @import("root").lib;
const interfaces: type = @import("root").interfaces;

const Modsys: type = @This();
const Module: type = interfaces.module.Module;
const Allocator: type = lib.kernel.allocation.Allocator;
const BitmapAllocator: type = lib.kernel.allocation.BitmapAllocator(8192);
const ModsysMenuconfigResolver: type = @import("ModsysMenuconfigResolver.zig");
const ModsysDependencyResolver: type = @import("ModsysDependencyResolver.zig");
const ModsysArchResolver: type = @import("ModsysArchResolver.zig");

modules: []Module,
bitmapAllocator: BitmapAllocator,

pub inline fn init(allModules: []Module) Modsys {
    return Modsys {
        .modules = allModules,
        .bitmapAllocator = BitmapAllocator.init(),
    };
}

pub inline fn run(self: *Modsys) void {
    const allocator: Allocator = self.bitmapAllocator.allocator();
    const menuconfigModulesResolved: []*const Module = ModsysMenuconfigResolver.init(self.modules).resolver(allocator);
    const archModulesResolved: []*const Module = ModsysArchResolver.init(menuconfigModulesResolved).resolver(allocator);
    allocator.free(menuconfigModulesResolved);
    const dependencyModulesResolved: []*const Module = ModsysDependencyResolver.init(archModulesResolved).resolver(allocator);
    allocator.free(archModulesResolved);

    inline for(dependencyModulesResolved) |module| {
        module.init() catch |err| {
            _ = err;
        };
    }

    self.bitmapAllocator.deinit();
}
