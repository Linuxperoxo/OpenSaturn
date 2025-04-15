// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: build.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
const opensaturnmain: type = @import("kernel/init/main.zig");

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
        .root_source_file = b.path("lib/saturn/libsat.zig"),
        .optimize = .ReleaseSmall,
        .stack_protector = false,
        .target = TargetConf,
    });

    const DriversMod = b.addModule("saturn/drivers", .{
        .root_source_file = b.path("drivers/drivers.zig"),
        .optimize = .ReleaseSmall,
        .stack_protector = false,
        .target = TargetConf,
    });

    const SaturnDevicesMod = b.addModule("saturn/devices", .{
        .root_source_file = b.path("kernel/devices/devices.zig"),
        .optimize = .ReleaseSmall,
        .stack_protector = false,
        .target = TargetConf,
    });
    
    Finalbinary.root_module.addImport("saturn/devices", SaturnDevicesMod);
    Finalbinary.root_module.addImport("saturn/cpu", SaturnCpuMod);
    Finalbinary.root_module.addImport("saturn/drivers", DriversMod);
    Finalbinary.root_module.addImport("saturn/lib", SaturnLibMod);
    //Finalbinary.root_module.addAssemblyFile(b.path("entry/entry.s")); // NOTE: Como o main.zig não usa extern fn extern const ... nos simbolos desse
                                                                        //       assembly, não precisamos linkar ele com o modulo root(main.zig), ou seja, todos os simbolos
                                                                        //       do assembly não serão visíveis para o main.zig
    Finalbinary.addAssemblyFile(b.path("entry/entry.s"));               // <= é isso que acontece aqui, já com root_module, o assembly é linkado ao modulo_root, assim todos os
                                                                        // símbolos são visíveis, podemos fazer extern fn _start() void;
    Finalbinary.setLinkerScript(b.path("linker.ld"));

    b.installArtifact(Finalbinary);
}

