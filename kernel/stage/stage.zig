// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: stage.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Stage_T: type = @import("types.zig").Stage_T;

var saturnStage: Stage_T = .boot;

pub fn stageSwitch(stage: Stage_T) void {
    saturnStage = stage;
}

pub fn stageGet() Stage_T {
    return saturnStage;
}
