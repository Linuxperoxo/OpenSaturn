// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ktask.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const sched: type = @import("sched.zig");
const listener: type = @import("listener.zig");

pub const KTask_T: type = types.KTask_T;
pub const KTaskChild_T: type = types.KTaskChild_T;
pub const KTaskPriority_T: type = types.KTaskPriority_T;

pub const sched_task = sched.sched_task;

pub const ktask_enable = listener.ktask_enable;
pub const ktask_disable = listener.ktask_disable;
