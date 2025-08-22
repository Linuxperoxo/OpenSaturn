// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: import.zig     │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const root: type = @import("../../build.zig");
const std: type = root.std;

const archResolvedFiles = root.files.archResolvedFiles;
const target = root.target.target;
const optimize = root.target.optimize;

pub const toImport_T: type = struct {
    name: []const u8,
    file: []const u8,
};

pub const importsToAdd = [_]toImport_T {



    // Kernel Arch Desc
    toImport_T {
        .name = "saturn/arch",
        .file = "arch.zig",
    },
    // =================



    // Kernel Internal
    toImport_T {
        .name = "saturn/kernel/core",
        .file = "kernel/core/core.zig",
    },

    toImport_T {
        .name = "saturn/kernel/exported",
        .file = "kernel/exported/exported.zig",
    },

    toImport_T {
        .name = "saturn/kernel/memory",
        .file = "kernel/memory/memory.zig",
    },
    // =================



    // Kernel Modules
    toImport_T {
        .name = "saturn/kernel/modules",
        .file = "modules.zig",
    },

    toImport_T {
        .name = "saturn/kernel/modules/interfaces",
        .file = "lib/saturn/interfaces/interfaces.zig",
    },
    // =================



    // Kernel Debug
    toImport_T {
        .name = "saturn/kernel/debug",
        .file = "debug.zig"
    },
    // =================




    // Kernel Supervisor
    toImport_T {
        .name = "saturn/kernel/supervisor",
        .file = "kernel/supervisor/supervisor.zig",
    },
    // =================



    // Kernel Config
    toImport_T {
        .name = "saturn/kernel/config",
        .file = "config/config.zig",
    },
    // =================



    // Kernel Loader
    toImport_T {
        .name = "saturn/kernel/loader",
        .file = "kernel/loader.zig",
    },
    // =================



    // Arch Depender
    toImport_T {
        .name = "saturn/kernel/lib",
        .file = archResolvedFiles.libk,
    },

    toImport_T {
        .name = "saturn/kernel/interrupts",
        .file = archResolvedFiles.interrupt,
    },

    toImport_T {
        .name = "saturn/userspace/lib",
        .file = archResolvedFiles.libs,
    },
    // =================
};


pub fn createImportsAndAddLinker(b: *std.Build, c: *std.Build.Step.Compile) void {
    inline for(importsToAdd) |import| {
        c.root_module.addImport(
            import.name,
            b.addModule(
                import.name,
                .{
                    .root_source_file = b.path(import.file),
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
    }
    c.setLinkerScript(b.path(archResolvedFiles.linker));
}
