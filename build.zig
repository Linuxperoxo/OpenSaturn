const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
    });

    const exe = b.addExecutable(.{
        .name = "sImage",
        .root_source_file = b.path("kernel/init/main.zig"),
        .target = target,
        .optimize = .ReleaseSmall,
    });

    exe.setLinkerScript(b.path("linker.ld"));

    const drivers = b.addModule("drivers", .{
        .root_source_file = b.path("drivers/mod.zig"),
    });

    const video = b.addModule("drivers/video", .{
        .root_source_file = b.path("drivers/video/console/mod.zig"),
    });

    exe.root_module.addImport("drivers/video", video);
    exe.addAssemblyFile(b.path("entry/entry.s"));
    exe.root_module.addImport("drivers", drivers);

    b.installArtifact(exe);
}

