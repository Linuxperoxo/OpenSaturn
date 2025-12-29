// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const types: type = @import("types.zig");

pub inline fn call_hooks(
    task: *types.KTask_T,
    comptime step: enum { init, ichilds, echilds, end }
) anyerror!void {
    switch(comptime step) {
        // init of task
        .init => {
            return if(task.hooks.start != null) task.hooks.start.?()
                else {};
        },

        // init of childs
        .ichilds => {
            return if(task.hooks.childs.start != null) task.hooks.childs.start.?()
                else {};
        },

        //end of childs
        .echilds => {
            return if(task.hooks.childs.exit != null) task.hooks.childs.exit.?()
                else {};
        },

        // end of task
        .end => {
            return if(task.hooks.exit != null) task.hooks.exit.?()
                else {};
        },
    }
}

pub inline fn call_task(task: *types.KTask_T) anyerror!*anyopaque {
    return task.task(task.param) catch |err| {
        task.flags.internal = .{
            .done = 1,
            .err = 1,
            .abort = 0,
            .childs = .{
                .done = 0,
                .err = 0,
            },
        };
        return err;
    };
}
