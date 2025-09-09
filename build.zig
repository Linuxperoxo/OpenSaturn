// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: build.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const std: type = @import("std");
pub const SaturnArchConfig: type = @import("config/arch/config.zig");

pub const target: std.Target.Cpu.Arch = switch(SaturnArchConfig.options.Target) {
    .x86 => .x86,
    .x86_64 => .x86_64,
    .arm => .arm,
    .avr => .avr,
    .xtensa => .xtensa,
};

pub const optimize: std.builtin.OptimizeMode = switch(SaturnArchConfig.options.OptimizeMode) {
    .Small => .ReleaseSmall,
    .Fast => .ReleaseFast,
};

pub export fn init() callconv(.c) void {}
pub export fn main() callconv(.c) void {}

pub fn build(b: *std.Build) void {
    const saturn = b.addExecutable(.{
        .name = "sImage",
        .root_module = b.addModule("kernel", .{
            .root_source_file = b.path("kernel/kernel.zig"),
        .target = b.resolveTargetQuery(.{
                .cpu_arch = target,
                .os_tag = .freestanding,
            }),
            .optimize = optimize,
            .stack_protector = false,
            .code_model = .kernel,
        }),
    });

    saturn.root_module.addImport(
        "saturn",
        b.addModule(
            "saturn",
            .{
                .root_source_file = b.path("saturn.zig"),
                .optimize = optimize,
                .stack_protector = false,
                .target = b.resolveTargetQuery(.{
                    .cpu_arch = target,
                    .os_tag = .freestanding,
                }),
                .code_model = .kernel,
            }
        )
    );

    const saturn_install = b.addInstallArtifact(saturn, .{});
    var saturn_step = b.step("saturn", "Install Saturn Binary");

    const fs: type = std.fs;
    const allocator = b.allocator;
    const cache_dir = b.cache_root;
    const path = fs.path.join(allocator, &.{
        cache_dir.path.?,
        @tagName(SaturnArchConfig.options.Target) ++ "-linker.ld",
    }) catch {
        @panic(
            @tagName(SaturnArchConfig.options.Target) ++
            " linker error"
        );
    };
    const file = fs.cwd().createFile(path, .{
        .truncate = true,
    }) catch {
        @panic(
            @tagName(SaturnArchConfig.options.Target) ++
            " linker error"
        );
    };
    _ = file.write(@import("saturn.zig").linker.__SaturnLinkerString__) catch {
        @panic(
            @tagName(SaturnArchConfig.options.Target) ++
            " linker error"
        );
    };

    saturn.setLinkerScript(b.path(path));

    saturn_step.makeFn = &struct {
        pub fn make(_: *std.Build.Step, _: std.Build.Step.MakeOptions) anyerror!void {
            if(SaturnArchConfig.options.CodeMode == .Debug) {
                std.debug.print("\x1b[33mWARNING:\x1b[0m Debug Mode Enable\n", .{});
            }
            return {};
        }
    }.make;

    saturn_step.dependOn(&saturn.step); // Compiler
    saturn_step.dependOn(&saturn_install.step); // Install binary
}

