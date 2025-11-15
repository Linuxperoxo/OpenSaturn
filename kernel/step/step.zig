// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: step.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const SaturnStepPhase_T: type = @import("types.zig").SaturnStepPhase_T;

var saturnCurrentStep: SaturnStepPhase_T = .boot;

pub fn saturn_set_phase(phase: SaturnStepPhase_T) void {
    saturnCurrentStep = phase;
}

pub fn saturn_get_phase() SaturnStepPhase_T {
    return saturnCurrentStep;
}
