// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");

pub inline fn call_hooks(
    task: *types.KTask_T,
    comptime step: enum { start, ichilds, echilds, exit }
) anyerror!void {
    return switch(comptime step) {
        // init of task
        .start => if(task.hooks.start != null) task.hooks.start.?()
            else {},

        // init of childs
        .schilds => if(task.hooks.childs.start != null) task.hooks.childs.start.?()
            else {},

        //end of childs
        .echilds => if(task.hooks.childs.exit != null) task.hooks.childs.exit.?()
            else {},

        // end of task
        .exit => if(task.hooks.exit != null) task.hooks.exit.?()
            else {},
    };
}

pub inline fn call_childs(task: *types.KTask_T) void {
    const child_aux: type = opaque {
        pub inline fn call_child_hook(child: *types.KTaskChild_T, comptime step: enum { start, exit }) anyerror!void {
            return switch(comptime step) {
                .start => if(child.start != null) child.start.?()
                    else {},

                .exit => if(child.exit != null) child.exit.?()
                    else {},
            };
        }

        pub inline fn push_failed_child(t: *types.KTask_T, failed: *types.KTaskChild_T) void {
            t.failed.?.push_in_list(
                &allocator.sba.allocator,
                failed
            ) catch unreachable;
        }

        pub inline fn call_child_task(t: *types.KTask_T, child: *types.KTaskChild_T) anyerror!void {
            return @call(.never_inline, child.task, .{
                if((t.flags.control.overflow & child.flags.control.allow) == 1) t.result
                    else null
            });
        }
    };
    for(task.childs.?.len) |i| {
        const child: *types.KTaskChild_T = &task.childs.?[i];
        child.flags.internal = .{};
        if(child.flags.control.block == 1)
            continue;
        child_aux.call_child_hook(child, .start) catch {
            child.flags.internal.abort = 1;
            child_aux.push_failed_child(task, child);
            continue;
        };
        child_aux.call_child_task(task, child) catch {
            child.flags.internal.err = 1;
            child_aux.push_failed_child(task, child);
            continue;
        };
        call_hooks(child, .exit) catch unreachable;
    }
}
