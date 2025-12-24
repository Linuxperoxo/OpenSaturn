// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fusium.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const fetch: type = @import("fetch.zig");

pub const FusiumDescription_T: type = types.FusiumDescription_T;
pub const FusiumDescriptionTarget_T: type = types.FusiumDescriptionTarget_T;

pub const fetch_fusioner = fetch.fetch_fusioner;
