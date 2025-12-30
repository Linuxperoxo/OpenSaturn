// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ktask.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const main: type = @import("main.zig");

pub const KTask_T: type = types.KTask_T;
pub const KTaskChild_T: type = types.KTaskChild_T;
pub const KTaskPriority_T: type = types.KTaskPriority_T;

pub const sched_task = main.sched_task;
