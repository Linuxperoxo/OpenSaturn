// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fusium.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const fetch: type = @import("fetch.zig");

pub const FusiumDescription: type = types.FusiumDescription;
pub const FusiumDescriptionTarget: type = types.FusiumDescriptionTarget;

pub const fetchFusioner = fetch.fetchFusioner;
