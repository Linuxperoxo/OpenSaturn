// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: build.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");

fn makemod(b: *std.Build, name: []const u8, root_source_file: []const u8) *std.Build.Module {
    return b.addModule(name, .{
        .root_source_file = b.path(root_source_file),
        .optimize = .ReleaseSmall,
        .stack_protector = false,
        .target = b.resolveTargetQuery(.{
            .os_tag = .freestanding,
            .cpu_arch = .x86,
        }),
    });
}

pub fn build(b: *std.Build) void {

    // Kernel Supported arch
    const x86 = makemod(b, "saturn/kernel/arch/x86", "kernel/arch/x86/x86.zig");
    const x86_64 = makemod(b, "saturn/kernel/arch/x86_64", "kernel/arch/x86_64/x86_64.zig");
    const arm = makemod(b, "saturn/kernel/arch/arm", "kernel/arch/arm/arm.zig");

    // Kernel
    const core = makemod(b, "saturn/kernel/core", "kernel/core/core.zig");
    const interfaces = makemod(b, "saturn/lib/interfaces", "lib/saturn/interfaces/interfaces.zig");
    const io = makemod(b, "saturn/lib/io", "lib/saturn/io/io.zig");

    // Final binary
    const binary = b.addExecutable(.{
        .name = "sImage",
        .root_module = b.addModule("kernel", .{
            .root_source_file = b.path("kernel/kernel.zig"),
            .target = b.resolveTargetQuery(.{
                .os_tag = .freestanding,
                .cpu_arch = .x86,
            }),
            .optimize = .ReleaseSmall,
            .stack_protector = false,
        }),
    });

    binary.root_module.addImport("saturn/kernel/arch/x86", x86);
    binary.root_module.addImport("saturn/kernel/arch/x86_64", x86_64);
    binary.root_module.addImport("saturn/kernel/arch/arm", arm);

    binary.root_module.addImport("saturn/kernel/core", core);
    binary.root_module.addImport("saturn/lib/interfaces", interfaces);
    binary.root_module.addImport("saturn/lib/io", io);

    binary.addAssemblyFile(b.path("entry/entry.s"));
    binary.setLinkerScript(b.path("linker.ld"));

    b.installArtifact(binary);
}

