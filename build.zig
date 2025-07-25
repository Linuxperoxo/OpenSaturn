// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: build.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
const SaturnArchInfo: type = @import("arch.zig");

const targetArch: std.Target.Cpu.Arch = switch(SaturnArchInfo.__SaturnTarget__) {
    .x86 => .x86,
    .x86_64 => .x86_64,
    .arm => .arm,
    .avr => .avr,
};
const optimize: std.builtin.OptimizeMode = switch(SaturnArchInfo.__SaturnOptimize__) {
    .Small => .ReleaseSmall,
    .Fast => .ReleaseFast,
};
const archFiles: ArchFiles_T =  ArchFiles_T {
    .linker = "linkers/" ++ SaturnArchInfo.__SaturnEnabledArchLinker__,
    .libk = "lib/saturn/kernel/" ++ @tagName(SaturnArchInfo.__SaturnTarget__) ++ "/lib.zig",
    .libs = "lib/saturn/userspace/" ++ @tagName(SaturnArchInfo.__SaturnTarget__) ++ "/lib.zig",
    .interrupt = if(SaturnArchInfo.__SaturnEnabledArchSupervisor__) 
        "kernel/interrupts/" ++ @tagName(SaturnArchInfo.__SaturnTarget__) ++ "/supervisor/" ++ "interrupts.zig"
    else
        "kernel/interrupts/" ++ @tagName(SaturnArchInfo.__SaturnTarget__) ++ "/supervisor/" ++ "interrupts.zig"
};

// Apenas para evitar um erro de linker
comptime {
    @export(&tmpM, .{
        .name = "main",
    });
    @export(&tmpM, .{
        .name = "init",
    });
}

fn tmpM() callconv(.c) void {}
fn tmpI() callconv(.c) void {}
//

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

const ArchFiles_T: type = struct {
    linker: []const u8,
    libk: []const u8,
    libs: []const u8,
    //module: []const u8,
    interrupt: []const u8,
};

pub fn build(b: *std.Build) void {
    // Kernel Supported arch
    const arch = makemod(b, "saturn/arch", "arch.zig");

    // Kernel
    const core = makemod(b, "saturn/kernel/core", "kernel/core/core.zig");
    const interfaces = makemod(b, "saturn/lib/interfaces", "lib/saturn/interfaces/interfaces.zig");
    const libk = makemod(b, "saturn/lib/kernel", archFiles.libk);
    const memory = makemod(b, "saturn/kernel/memory", "kernel/memory/kmem.zig");

    // Kernel Modules
    const modules = makemod(b, "saturn/modules", "modules.zig");

    // Debug
    const debug = makemod(b, "saturn/debug", "debug.zig");

    // Supervisor
    const supervisor = makemod(b, "saturn/kernel/supervisor", "kernel/supervisor/supervisor.zig");

    // Arch interrupts
    const interrupt = makemod(b, "saturn/kernel/interrupts", archFiles.interrupt);

    // Userspace
    const libs = makemod(b, "saturn/lib", archFiles.libs);

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

    const menuconfig = b.addRunArtifact(modsys);
    const menuconfig_step = b.step("menuconfig", "Saturn menuconfig");

    menuconfig_step.dependOn(&menuconfig.step);
    // End Of Menuconfig

    binary.root_module.addImport("saturn/arch", arch);
    binary.root_module.addImport("saturn/interrupts", interrupt);
    binary.root_module.addImport("saturn/kernel/core", core);
    binary.root_module.addImport("saturn/lib/interfaces", interfaces);
    binary.root_module.addImport("saturn/lib/kernel", libk);
    binary.root_module.addImport("saturn/kernel/memory", memory);
    binary.root_module.addImport("saturn/modules", modules);
    binary.root_module.addImport("saturn/debug", debug);
    binary.root_module.addImport("saturn/supervisor", supervisor);
    binary.root_module.addImport("saturn/lib", libs);

    binary.setLinkerScript(b.path(archFiles.linker));

    if(SaturnArchInfo.__SaturnCodeModel__ == .Debug) {
        std.debug.print("\x1b[33mWARNING:\x1b[0m Debug Mode Enable\n", .{});
    }

    const saturn = b.addInstallArtifact(binary, .{});
    const saturn_step = b.step("saturn", "Install Saturn Binary");

    saturn_step.dependOn(&binary.step);
    saturn_step.dependOn(&saturn.step);
}

