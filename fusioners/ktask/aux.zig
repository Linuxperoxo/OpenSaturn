// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");

pub inline fn call_task(task: *types.KTask_T) anyerror!void {
    defer task.flags.internal.done = 1;
    task.result = task.task(task.param) catch |err| {
        task.flags.internal.err = 1;
        return err;
    };
}

pub inline fn call_childs(task: *types.KTask_T) void {
    if(task.childs == null) return;
    task.flags.internal.childs.done = 1;
    for(0..task.childs.?.len) |i| {
        const child: *types.KTaskChild_T = &task.childs.?[i];
        child.flags.internal = .{};
        if((child.flags.control.depend & task.flags.internal.err) == 1
            or child.flags.control.pendent == 0) {
            task.flags.internal.childs.done = 0;
            continue;
        }
        @call(.never_inline, child.task, .{ task.result }) catch {
            child.flags.internal.err = 1;
            task.flags.internal.childs.err = 1;
            continue;
        };
        if(child.exit != null)
            @call(.never_inline, child.exit.?, .{});
    }
}
