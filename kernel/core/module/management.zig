// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const module: type = @import("root").interfaces.module;

const ModuleStatus: type = enum(u2) {
    uninitialized,
    running,
    undefined,
};

const moduleRoot: struct {
    next: ?*@This(),
    prev: ?*@This(),
    this: ?*module.Module_T,
    status: ModuleStatus,
} = .{
    .next = null,
    .prev = null,
    .module = null,
    .status = .undefined,
};

pub fn stallmod() void {
    var currentModuleToLoad: ?*@TypeOf(moduleRoot) = moduleRoot;
    while(currentModuleToLoad) |NonNullCurrent| {
        if(NonNullCurrent.this) |NonNullThis| {
            NonNullThis.init();
        }
        currentModuleToLoad = NonNullCurrent.next;
    }
}
