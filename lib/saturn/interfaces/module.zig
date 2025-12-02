// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").core.module;

pub const ModType_T: type = module.ModType_T;
pub const Mod_T: type = module.Mod_T;
pub const ModErr_T: type = module.ModErr_T;
pub const ModuleDescriptionTarget_T: type =  module.ModuleDescriptionTarget_T;
pub const ModuleDescription_T: type = module.ModuleDescription_T;

pub const srchmod = module.srchmod;
pub const inmod = module.inmod;
pub const rmmod = module.rmmod;
