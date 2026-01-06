// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: sched.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");

const default_priority: types.KTaskPriority_T = types.KTaskPriority_T.normal;

var tasks = [_]types.ListKTask_T {
    .{},
} ** @typeInfo(types.KTaskPriority_T).@"enum".fields.len;

var current_priority: types.KTaskPriority_T = .highly;

pub fn sched_task(task: *types.KTask_T, priority: ?types.KTaskPriority_T) types.KTaskErr_T!void {
    const task_prio = priority orelse default_priority;
    const task_list: *types.ListKTask_T = &tasks[@intFromEnum(task_prio)];
    if(!task_list.is_initialized()) task_list.init(
        &allocator.sba.allocator
    ) catch return types.KTaskErr_T.SchedPriorityInitError;
    task_list.push_in_list(
        &allocator.sba.allocator,
        task,
    ) catch return types.KTaskErr_T.SchedFailed;
}

pub fn sched_tasks(priority: types.KTaskPriority_T) usize {
    return tasks[@intFromEnum(priority)].how_many_nodes();
}

pub fn sched_run(priority: ?types.KTaskPriority_T) void {
    defer r: {
        if(priority != null and priority.? != current_priority) break :r {};
        current_priority = switch(current_priority) {
            .low => types.KTaskPriority_T.highly,
            else => @enumFromInt(@intFromEnum(current_priority) + 1),
        };
    }
    const task_list: *types.ListKTask_T = &tasks[@intFromEnum(priority orelse current_priority)];
    if(!task_list.is_initialized()) return;
    task_list.iterator_reset() catch unreachable;
    while(task_list.iterator()) |task| {
        task.flags.internal = .{};
        sw: switch((enum { flags, task, exit, drop }).flags) {
            .flags => {
                if(task.flags.control.drop == 1) continue :sw .drop;
                if(task.flags.control.pendent == 0) break :sw {};
                continue :sw .task;
            },

            .task => {
                if(aux.call_task(task)) |_| {} else |_| {
                    if(task.flags.control.stop == 1) break :sw {};
                }
                aux.call_childs(task);
                continue :sw .exit;
            },

            .exit => {
                if(task.exit != null) @call(.never_inline, task.exit.?, .{});
                if(task.flags.control.single == 1) continue :sw .drop;
            },

            .drop => {
                task_list.drop_on_list(
                    (task_list.iterator_index() catch unreachable) - 1,
                    &allocator.sba.allocator
                ) catch unreachable;
                if(task_list.how_many_nodes() == 0) task_list.deinit(&allocator.sba.allocator) catch unreachable;
            },
        }
    } else |err| switch(err) {
        types.ListKTaskErr_T.EndOfIterator => {},
        else => {
            @branchHint(.unlikely);
            // klog()
        },
    }
}
