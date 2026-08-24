// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ar.zig     │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

// Architecture Resolver

// o architecture resolver é responsável por obter o código de implementação
// da arquitetura target, tornando esse código visível para todo o kernel.

const config: type = @import("root").config;
const arch: type = @import("root").interfaces.arch;
const codes: type = @import("root").codes;
const builtin: type = @import("std").builtin;
const aux: type = @import("aux.zig");

comptime {
    for(codes.__SaturnArchManifests__, 0..) |manifest, i| {
        for(codes.__SaturnArchManifests__[0..i]) |other_manifest| {
            if(other_manifest.target == manifest.target) @compileError(
                "target \"" ++ @tagName(manifest.target) ++ "\" duplicate implementation in codes.zig"
            );
        }
    }
}

pub const arch_impl = r: {
    const manifest: arch.ArchManifest_T = t: {
        for(codes.__SaturnArchManifests__) |manifest|
            if(manifest.target == config.arch.options.Target)
                break :t manifest;
        @compileError("target \"" ++ @tagName(config.arch.options.Target) ++ "\" does not have implementation");
    };

    // .target and .arch is required
    var manifest_fields: [
        if(manifest.exposed != null) 2 + manifest.exposed.?.len
        else 2
    ]builtin.Type.StructField = undefined;

    manifest_fields[0].name = "target";
    manifest_fields[0].type = arch.Target_T;
    manifest_fields[0].default_value_ptr = &manifest.target;
    manifest_fields[0].is_comptime = true;
    manifest_fields[0].alignment = 1;


    manifest_fields[1].name = "arch";
    manifest_fields[1].type = type;
    manifest_fields[1].default_value_ptr = &manifest.arch;
    manifest_fields[1].is_comptime = true;
    manifest_fields[1].alignment = 1;

    if(manifest.exposed) |exposed| {
        for(2..manifest_fields.len) |i| {
            manifest_fields[i].name = @ptrCast(exposed[i - 2].name);
            manifest_fields[i].default_value_ptr = &exposed[i - 2].container;
            manifest_fields[i].type = type;
            manifest_fields[i].is_comptime = true;
            manifest_fields[i].alignment = 1;
        }
    }

    break :r @Type(.{
        .@"struct" = .{
            .fields = &manifest_fields,
            .decls = &[_]builtin.Type.Declaration {},
            .is_tuple = false,
            .layout = .auto,
        },
    }) {};
};
