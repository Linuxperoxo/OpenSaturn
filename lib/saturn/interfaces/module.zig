// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const ModuleFunc_T: type = enum(u2) {
    driver,
    filesystem,
    syscall,
};

pub const Module_T: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    type: ModuleFunc_T,
    init: fn() u32,
    exit: fn() u32,
};

const ModuleStatus: type = enum(u2) {
    uninitialized,
    running,
    undefined,
};

const moduleRoot: struct {
    next: ?*@This(),
    prev: ?*@This(),
    this: ?*Module_T,
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

pub fn inmod(module: Module_T) void {

}

pub fn rmmod(name: [:0]const u8) void {

}

