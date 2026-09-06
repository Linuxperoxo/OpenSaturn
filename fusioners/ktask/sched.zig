// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: sched.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");

const default_priority: types.KTaskPriority = types.KTaskPriority.normal;

var tasks = [_]types.ListKTask {
    .{},
} ** @typeInfo(types.KTaskPriority).@"enum".fields.len;

var current_priority: types.KTaskPriority = .highly;

pub fn schedTask(task: *types.KTask, priority: ?types.KTaskPriority) types.KTaskErr!void {
    const task_prio = priority orelse default_priority;
    const task_list: *types.ListKTask = &tasks[@intFromEnum(task_prio)];
    if(!task_list.isInitialized()) task_list.init(
        &allocator.sba.allocator
    ) catch return types.KTaskErr.SchedPriorityInitError;
    task_list.pushInList(
        &allocator.sba.allocator,
        task,
    ) catch return types.KTaskErr.SchedFailed;
}

pub fn schedTasks(priority: types.KTaskPriority) usize {
    return tasks[@intFromEnum(priority)].howManyNodes();
}

pub fn schedRun(priority: ?types.KTaskPriority) void {
    defer r: {
        if(priority != null and priority.? != current_priority) break :r {};
        current_priority = switch(current_priority) {
            .low => types.KTaskPriority.highly,
            else => @enumFromInt(@intFromEnum(current_priority) + 1),
        };
    }
    const task_list: *types.ListKTask = &tasks[@intFromEnum(priority orelse current_priority)];
    if(!task_list.isInitialized()) return;
    task_list.iteratorReset() catch unreachable;
    while(task_list.iterator()) |task| {
        task.flags.internal = .{};
        sw: switch((enum { flags, task, exit, drop }).flags) {
            .flags => {
                if(task.flags.control.drop == 1) continue :sw .drop;
                if(task.flags.control.pendent == 0) break :sw {};
                continue :sw .task;
            },

            .task => {
                if(aux.callTask(task)) |_| {} else |_| {
                    if(task.flags.control.stop == 1) break :sw {};
                }
                aux.callChilds(task);
                continue :sw .exit;
            },

            .exit => {
                if(task.exit != null) @call(.never_inline, task.exit.?, .{});
                if(task.flags.control.single == 1) continue :sw .drop;
            },

            .drop => {
                task_list.dropOnList(
                    (task_list.iteratorIndex() catch unreachable) - 1,
                    &allocator.sba.allocator
                ) catch unreachable;
                if(task_list.howManyNodes() == 0) task_list.deinit(&allocator.sba.allocator) catch unreachable;
            },
        }
    } else |err| switch(err) {
        types.ListKTaskErr.EndOfIterator => {},
        else => {
            @branchHint(.unlikely);
            // klog()
        },
    }
}
