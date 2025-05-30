// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: build.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");

pub fn build(b: *std.Build) void {
    const TargetConf = b.resolveTargetQuery(.{
        .os_tag = .freestanding,
        .cpu_arch = .x86,
    });
    const Finalbinary = b.addExecutable(.{
        .name = "sImage",
        .root_module = b.addModule("main", .{
            .root_source_file = b.path("kernel/init/main.zig"),
            .target = TargetConf,
            .optimize = .ReleaseSmall,
            .stack_protector = false,
        }),
    });
    const SaturnCpuMod = b.addModule("saturn/cpu", .{
        .root_source_file = b.path("kernel/cpu/cpu.zig"),
        .optimize = .ReleaseSmall,
        .stack_protector = false,
        .target = TargetConf,
    });
    const SaturnLibMod = b.addModule("saturn/lib", .{
        .root_source_file = b.path("lib/saturn/saturn.zig"),
        .optimize = .ReleaseSmall,
        .stack_protector = false,
        .target = TargetConf,
    });

    Finalbinary.root_module.addImport("saturn/cpu", SaturnCpuMod);
    Finalbinary.root_module.addImport("saturn/lib", SaturnLibMod);

    Finalbinary.addAssemblyFile(b.path("entry/entry.s"));
    Finalbinary.setLinkerScript(b.path("linker.ld"));

    b.installArtifact(Finalbinary);
}

