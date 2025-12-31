// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
const sched: type = @import("sched.zig");
const types: type = @import("types.zig");

test "Adding Task" {
    var calling_count: usize = 0;
    var task: types.KTask_T = .{
        .param = &calling_count,
        .exit = null,
        .childs = null,
        .task = &opaque {
            pub fn task(count: ?*anyopaque) anyerror!?*anyopaque {
                @as(*usize, @alignCast(@ptrCast(count))).* += 1;
                return null;
            }
        }.task,
        .flags = .{
            .control = .{
                .pendent = 1,
                .single = 0,
                .stop = 1,
                .drop = 0,
            },
        },
    };
    try sched.sched_task(&task, types.KTaskPriority_T.highly);
    inline for(0..2) |i| {
        sched.sched_run(types.KTaskPriority_T.highly);
        sched.sched_run(types.KTaskPriority_T.highly);
        if(calling_count != (
            if(i == 0) 2 else 1
        )) return if(i == 0) error.CallingError else error.SigleNotDrop;
        task.flags.control.single = if(i == 0) 1 else 0;
        calling_count = 0;
    }
    try sched.sched_task(&task, types.KTaskPriority_T.highly);
    task.flags.control.pendent = 0;
    sched.sched_run(types.KTaskPriority_T.highly);
    if(calling_count != 0) return error.PendentTaskCall;
}

test "Task Internal Flags Test" {
    var task: types.KTask_T = .{
        .param = null,
        .exit = null,
        .childs = null,
        .task = &opaque {
            pub fn task(_: ?*anyopaque) anyerror!?*anyopaque {
                return error.TaskFailed;
            }
        }.task,
        .flags = .{
            .control = .{
                .pendent = 1,
                .single = 0,
                .stop = 1,
                .drop = 0,
            },
        },
    };
    try sched.sched_task(&task, types.KTaskPriority_T.highly);
    sched.sched_run(types.KTaskPriority_T.highly);
    if(task.flags.internal.done == 0) return error.TaskPedentNotCall;
    if(task.flags.internal.err == 0) return error.TaskWithoutError;
    task.flags.control.pendent = 0;
    sched.sched_run(types.KTaskPriority_T.highly);
    if(task.flags.internal.done == 1) return error.TaskNotPedentCall;
}

const StructTest_T: type = struct {
    counter: usize,
    err: bool,
};

test "Adding Task With Childs" {
    var test_info: StructTest_T = .{
        .counter = 0,
        .err = true,
    };
    var childs = [_]types.KTaskChild_T {
        .{
            .task = &opaque {
                pub fn task(count: ?*anyopaque) anyerror!void {
                    @as(*StructTest_T, @alignCast(@ptrCast(count))).counter += 1;
                }
            }.task,
            .exit = null,
            .flags = .{
                .control = .{
                    .depend = 0,
                    .pendent = 1,
                },
            },
        }
    } ** 2;
    var task: types.KTask_T = .{
        .param = &test_info,
        .exit = null,
        .childs = childs[0..2],
        .task = &opaque {
            pub fn task(param: ?*anyopaque) anyerror!?*anyopaque {
                return if(@as(*StructTest_T, @alignCast(@ptrCast(param))).err) error.Some else
                    param;
            }
        }.task,
        .flags = .{
            .control = .{
                .pendent = 1,
                .single = 0,
                // aqui testamos o stop, ja que caso nao funcione, vamos ter um segfault
                // logo na primeira chamada do child
                .stop = 1,
                .drop = 0,
            },
        },
    };
    try sched.sched_task(&task, types.KTaskPriority_T.high);
    sched.sched_run(types.KTaskPriority_T.high);
    if(test_info.counter != 0) return error.DependChildRun;
    test_info.err = false;
    childs[0].flags.control.depend = 1;
    childs[1].flags.control.depend = 1;
    sched.sched_run(types.KTaskPriority_T.high);
    if(test_info.counter != 2) return error.ChildsNotCall;
}
