// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").core.module;

pub const ModType_T: type = module.ModType_T;
pub const Mod_T: type = module.Mod_T;
pub const ModControlFlags_T: type = module.ModControlFlags_T;
pub const ModErr_T: type = module.ModErr_T;
pub const ModuleDescriptionTarget_T: type =  module.ModuleDescriptionTarget_T;
pub const ModuleDescription_T: type = module.ModuleDescription_T;
pub const ModuleDescriptionLibMine_T: type = module.ModuleDescriptionLibMine_T;
pub const ModuleDescriptionLibOut_T: type = module.ModuleDescriptionLibOut_T;

pub const initmod = module.initmod;
pub const killmod = module.killmod;
pub const schmod = module.schmod;
