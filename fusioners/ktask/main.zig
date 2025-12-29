// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const listener: type = @import("listener.zig");
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");

var current_priority: ?types.KTaskPriority_T = null;
var tasks = [_]types.ListKTask_T {
    .{},
} ** @typeInfo(types.KTaskPriority_T).@"enum".fields.len;

pub fn sched_task(task: *types.KTask_T, priority: ?types.KTaskPriority_T) void {
    const task_prio = priority orelse types.KTaskPriority_T.normal;
    const task_list: *types.ListKTask_T = &tasks[
        @intFromEnum(task_prio)
    ];
    if(!task_list.is_initialized()) task_list.init(&allocator.sba.allocator);
    task_list.push_in_list(
        &allocator.sba.allocator,
        task,
    ) catch return types.KTaskErr_T.SchedFailed;
}

pub fn sched_run(priority: ?types.KTaskPriority_T) void {
    current_priority = if(current_priority == null) types.KTaskPriority_T.highly
        else current_priority;
    const task_list: *types.ListKTask_T = &tasks[
        @intFromEnum(current_priority)
    ];
    if(!task_list.is_initialized()) return;
    while(task_list.iterator()) |task| {
        // call_hooks inline
        aux.call_hooks(task, .init) catch {
            task.flags.internal = .{
                .done = 0,
                .err = 0,
                .abort = 1,
                .childs = .{
                    .done = 0,
                    .err = 0,
                },
            };
            continue;
        };
        aux.call_task(task) catch continue;
        task.flags.internal = .{
            .done = 1,
            .err = 0,
            .abort = 0,
            .childs = .{
                .done = 0,
                .err = 0,
            },
        };

    } else |err| switch(err) {

    }
}
