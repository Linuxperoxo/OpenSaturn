// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: build.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const std: type = @import("std");
pub const SaturnArchInfo: type = @import("arch.zig");

pub const target: type = @import("build/target/target.zig");
pub const import: type = @import("build/import/import.zig");
pub const files: type = @import("build/files/files.zig");

pub export fn init() callconv(.c) void {}
pub export fn main() callconv(.c) void {}

pub fn build(b: *std.Build) void {
    const saturn = b.addExecutable(.{
        .name = "sImage",
        .root_module = b.addModule("kernel", .{
            .root_source_file = b.path("kernel/kernel.zig"),
        .target = b.resolveTargetQuery(.{
                .cpu_arch = target.target,
                .os_tag = .freestanding,
            }),
            .optimize = target.optimize,
            .stack_protector = false,
            .code_model = .kernel,
        }),
    });

    const saturn_install = b.addInstallArtifact(saturn, .{});
    const saturn_step = b.step("saturn", "Install Saturn Binary");

    import.createImportsAndAddLinker(b, saturn);

    if(SaturnArchInfo.__SaturnCodeModel__ == .Debug) {
        std.debug.print("\x1b[33mWARNING:\x1b[0m Debug Mode Enable\n", .{});
    }

    saturn_step.dependOn(&saturn.step); // Compiler
    saturn_step.dependOn(&saturn_install.step); // Install binary
}

