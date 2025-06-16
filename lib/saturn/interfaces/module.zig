// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const module: type = @import("root").core.module;
const interfaces: type = module.interfaces;

pub const ModType_T: type = interfaces.ModType_T;
pub const Mod_T: type = interfaces.Mod_T;

pub const inmod: fn(Mod_T) usize = interfaces.inmod;
pub const rmmod: fn([]const u8) usize = interfaces.rmmod;
