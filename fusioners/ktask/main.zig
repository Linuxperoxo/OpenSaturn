// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
//const listener: type = @import("listener.zig");
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");

var current_priority: types.KTaskPriority_T = .highly;
var tasks = [_]types.ListKTask_T {
    .{},
} ** @typeInfo(types.KTaskPriority_T).@"enum".fields.len;

pub fn sched_init() anyerror!void {
    
}

pub fn sched_task(task: *types.KTask_T, priority: ?types.KTaskPriority_T) void {
    const task_prio = priority orelse types.KTaskPriority_T.normal;
    const task_list: *types.ListKTask_T = &tasks[@intFromEnum(task_prio)];
    if(!task_list.is_initialized()) task_list.init(&allocator.sba.allocator);
    task_list.push_in_list(
        &allocator.sba.allocator,
        task,
    ) catch return types.KTaskErr_T.SchedFailed;
}

pub fn sched_run() void {
    const task_list: *types.ListKTask_T = &tasks[@intFromEnum(current_priority)];
    if(!task_list.is_initialized()) return;
    task_list.iterator_reset() catch unreachable;
    while(task_list.iterator()) |task| {
        task.flags.internal = .{};
        // call_hooks inline
        aux.call_hooks(task, .start) catch {
            task.flags.internal.abort = 1;
            continue;
        };
        task.result = task.task(task.param) catch {
            task.flags.internal.done = 1;
            task.flags.internal.err = 1;
            continue;
        };
        task.flags.internal.done = 1;
        aux.call_hooks(task, .schilds) catch {
            task.flags.internal.childs = .{
                .done = 0,
                .err = 0,
                .abort = 1,
            };
            continue;
        };
        if(task.childs != null) {
            aux.call_childs(task);
            aux.call_hooks(task, .echilds);
        }
        aux.call_hooks(task, .exit);
    } else |err| switch(err) {
        types.ListKTaskErr_T.EndOfIterator => {},
        else => {
            // klog()
        },
    }
    current_priority = switch(current_priority) {
        .low => types.KTaskPriority_T.highly,
        else => @enumFromInt(@intFromEnum(current_priority) + 1),
    };
}
