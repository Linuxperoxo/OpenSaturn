// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const drivers: type = @import("root").drivers;
const memory: type = @import("root").memory;
const fs: type = @import("root").fs;

pub const ModuleType: type = enum(u1) {
    driver,
    filesystem,
};

pub const ModuleStatus: type = enum(u2) {
    Uninitialized,
    Running,
    Deleted,
};

pub const ModuleInterface: type = struct {
    name: []const u8,
    desc: []const u8,
    version: []const u8,
    author: []const u8,
    type: ModuleType = undefined,
    status: ModuleStatus = .Uninitialized,
    init: fn() u32,
    exit: fn() u32,
};

const ModuleQueue: type = struct {
    next: ?*ModuleQueue,
    prev: ?*ModuleQueue,
    this: ?*ModuleInterface,
};

const moduleRoot: struct { next: ?*ModuleQueue, prev: ?*ModuleQueue, this: ?*ModuleInterface} = .{
    .next = null,
    .prev = null,
    .module = null,
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

pub fn inmod(module: ModuleInterface) void {
    var currentModule: *ModuleQueue = moduleRoot;
    while(currentModule.next) |_| : (currentModule = currentModule.next) {

    }
    const newModule = memory.kmem.alloc(1, ModuleQueue);

    currentModule.next = newModule.ptr;
    currentModule.next.?.prev = currentModule;
    currentModule.next.?.module.?.name = module.name;
    currentModule.next.?.module.?.version = module.version;
    currentModule.next.?.module.?.type = module.type;
    currentModule.next.?.module.?.status = module.status;
    currentModule.next.?.module.?.init = module.init;
    currentModule.next.?.module.?.exit = module.exit;
}

pub fn rmmod(name: [:0]const u8) void {
    _ = name;
}

pub fn scmod(name: [:0]const u8) ?*ModuleQueue {
    _ = name;
}
