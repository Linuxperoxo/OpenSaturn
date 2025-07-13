// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: build.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");

// NOTE: Para modificar a arquitetura alvo do kernel,
//       modifique '.cpu_arch' por uma arquitetura
//       suportada pelo opensaturn
const targetArch: std.Target.Cpu.Arch = .x86;
const optimize: std.builtin.OptimizeMode = .ReleaseSmall;

fn makemod(b: *std.Build, name: []const u8, root_source_file: []const u8) *std.Build.Module {
    return b.addModule(name, .{
        .root_source_file = b.path(root_source_file),
        .optimize = optimize,
        .stack_protector = false,
        .target = b.resolveTargetQuery(.{
            .cpu_arch = targetArch,
            .os_tag = .freestanding,
        }),
        .code_model = .kernel,
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
    const memory = makemod(b, "saturn/kernel/memory", "kernel/memory/kmem.zig");

    // Kernel Modules
    const modules = makemod(b, "saturn/modules", "modules.zig");
    const linker = makemod(b, "saturn/linker", "lib/saturn/interfaces/linker.zig");

    // Debug
    const debug = makemod(b, "saturn/debug", "debug.zig");

    // Final binary
    const binary = b.addExecutable(.{
        .name = "sImage",
        .root_module = b.addModule("kernel", .{
            .root_source_file = b.path("kernel/kernel.zig"),
        .target = b.resolveTargetQuery(.{
                .cpu_arch = targetArch,
                .os_tag = .freestanding,
            }),
            .optimize = optimize,
            .stack_protector = false,
            .code_model = .kernel,
        }),
    });

    // Menuconfig
    const saturnmodules = b.addModule("saturn/modules", .{
        .root_source_file = b.path("modules.zig"),
    });

    const modsys = b.addExecutable(.{
        .name = "modsys",
        .root_source_file = b.path("menuconfig/modsys.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = .ReleaseFast,
    });

    modsys.root_module.addImport("saturn/modules", saturnmodules);
    saturnmodules.addImport("saturn/linker", linker);

    const menuconfig = b.addRunArtifact(modsys);
    const menuconfig_step = b.step("menuconfig", "Saturn menuconfig");

    menuconfig_step.dependOn(&menuconfig.step);
    // End Of Menuconfig

    modules.addImport("saturn/linker", linker);

    binary.root_module.addImport("saturn/kernel/arch/x86", x86);
    binary.root_module.addImport("saturn/kernel/arch/x86_64", x86_64);
    binary.root_module.addImport("saturn/kernel/arch/arm", arm);

    binary.root_module.addImport("saturn/kernel/core", core);
    binary.root_module.addImport("saturn/lib/interfaces", interfaces);
    binary.root_module.addImport("saturn/lib/io", io);
    binary.root_module.addImport("saturn/kernel/memory", memory);
    binary.root_module.addImport("saturn/modules", modules);
    binary.root_module.addImport("saturn/linker", linker);

    binary.root_module.addImport("saturn/debug", debug);

    binary.addAssemblyFile(b.path("entry/entry.s"));
    binary.setLinkerScript(b.path("linker.ld"));

    if(optimize == .ReleaseSmall) {
        std.debug.print("\x1b[33mWARNING:\x1b[0m Debug Mode Enable\n", .{});
    }

    const saturn = b.addInstallArtifact(binary, .{});
    const saturn_step = b.step("saturn", "Install Saturn Binary");

    saturn_step.dependOn(&binary.step);
    saturn_step.dependOn(&saturn.step);
}

