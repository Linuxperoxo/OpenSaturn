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

modules: []*const Module,
bitmapAllocator: BitmapAllocator,

pub fn init(allModules: []*const Module) Modsys {
    return Modsys {
        .modules = allModules,
        .bitmapAllocator = BitmapAllocator.init(),
    };
}

pub fn run(self: *Modsys) void {
    ModsysMenuconfigResolver.init(self.modules).resolver(self.bitmapAllocator.allocator())


    const modsysDependencyResolver: ModsysDependencyResolver = ModsysDependencyResolver.init(

    );
}
