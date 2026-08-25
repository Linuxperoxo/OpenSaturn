// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").core.module;

pub const ModType: type = module.ModType;
pub const Mod: type = module.Mod;
pub const ModControlFlags: type = module.ModControlFlags;
pub const ModErr: type = module.ModErr;
pub const ModuleDescriptionTarget: type =  module.ModuleDescriptionTarget;
pub const ModuleDescription: type = module.ModuleDescription;
pub const ModuleDescriptionLibMine: type = module.ModuleDescriptionLibMine;
pub const ModuleDescriptionLibOut: type = module.ModuleDescriptionLibOut;

pub const initmod = module.initmod;
pub const killmod = module.killmod;
pub const schmod = module.schmod;
