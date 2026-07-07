// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: build.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");

const arch: type = @import("config/arch/config.zig");
const compile: type = @import("config/compile/config.zig");
const linkers = @import("linkers.zig") {};

comptime {
    if(!@hasField(@TypeOf(linkers), @tagName(arch.options.Target)))
        @compileError("");
}

pub const target: std.Target.Cpu.Arch = switch(arch.options.Target) {
    .i386 => .x86,
    .amd64 => .x86_64,
    .arm => .arm,
    .avr => .avr,
    .xtensa => .xtensa,
    .riscv64 => .riscv,
};

pub const optimize: std.builtin.OptimizeMode = switch(compile.options.OptimizeMode) {
    .Small => .ReleaseSmall,
    .Fast => .ReleaseFast,
};

pub fn build(b: *std.Build) void {
    const saturn = b.addExecutable(.{
        .name = "sImage.elf",
        .root_module = b.addModule("kernel", .{
            .root_source_file = b.path("kernel/kernel.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = target,
                .os_tag = .freestanding,
            }),
            .optimize = optimize,
            .stack_protector = false,
            .code_model = .default,
            .imports = &[_]std.Build.Module.Import {
                .{
                    .name = "saturn",
                    .module = b.addModule(
                        "saturn",
                        .{
                            .root_source_file = b.path("saturn.zig"),
                            .optimize = optimize,
                            .stack_protector = false,
                            .target = b.resolveTargetQuery(.{
                                .cpu_arch = target,
                                .os_tag = .freestanding,
                            }),
                        }
                    ),
                },
            },
        }),
    });

    const saturn_install = b.addInstallArtifact(saturn, .{});
    var saturn_step = b.step("saturn", "Install Saturn Binary");

    const fs: type = std.fs;
    const allocator = b.allocator;
    const cache_dir = b.cache_root;
    const path = fs.path.join(allocator, &.{
        cache_dir.path.?,
        @tagName(arch.options.Target) ++ "-linker.ld",
    }) catch {
        @panic(
            @tagName(arch.options.Target) ++
            " linker error"
        );
    };
    const file = fs.cwd().createFile(path, .{
        .truncate = true,
    }) catch {
        @panic(
            @tagName(arch.options.Target) ++
            " linker error"
        );
    };
    _ = file.write(@field(linkers, @tagName(arch.options.Target))) catch {
        @panic(
            @tagName(arch.options.Target) ++
            " linker error"
        );
    };

    saturn.setLinkerScript(b.path(path));
    saturn.root_module.addIncludePath(b.path("include"));

    saturn_step.dependOn(&saturn.step); // Compiler
    saturn_step.dependOn(&saturn_install.step); // Install binary
}

