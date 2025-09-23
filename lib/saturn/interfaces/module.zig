// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").core.module;
const interfaces: type = module.interfaces;
const management: type = module.management;

pub const ModType_T: type = interfaces.ModType_T;
pub const Mod_T: type = interfaces.Mod_T;
pub const ModErr_T: type = interfaces.ModErr_T;
pub const ModuleDescriptionTarget_T: type =  interfaces.ModuleDescriptionTarget_T;
pub const ModuleDescription_T: type = interfaces.ModuleDescription_T;

pub const inmod = management.inmod;
pub const rmmod = management.rmmod;

// pub const alloc = interfaces.alloc;
// pub const free = interfaces.free;
