// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: step.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const SaturnStepPhase_T: type = @import("types.zig").SaturnStepPhase_T;

var saturnCurrentStep: SaturnStepPhase_T = .boot;

pub fn saturnSetPhase(phase: SaturnStepPhase_T) void {
    saturnCurrentStep = phase;
}

pub fn saturnGetPhase() SaturnStepPhase_T {
    return saturnCurrentStep;
}
