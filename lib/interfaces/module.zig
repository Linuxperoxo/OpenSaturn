// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").core.module;

pub const ModType: type = module.ModType_T;
pub const Mod: type = module.Mod_T;
pub const ModControlFlags: type = module.ModControlFlags_T;
pub const ModErr: type = module.ModErr_T;
pub const ModuleDescriptionTarget: type =  module.ModuleDescriptionTarget_T;
pub const ModuleDescription: type = module.ModuleDescription_T;
pub const ModuleDescriptionLibMine: type = module.ModuleDescriptionLibMine_T;
pub const ModuleDescriptionLibOut: type = module.ModuleDescriptionLibOut_T;

pub const initmod = module.initmod;
pub const killmod = module.killmod;
pub const schmod = module.schmod;
