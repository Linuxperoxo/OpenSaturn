// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modsys.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const deps: type = @import("deps.zig");

pub fn saturn_modules_loader() void {
    inline for(comptime deps.resolve_dependencies()) |module| {
        // Skip nao pode ser comptime se nao vamos ter um
        // erro de compilacao, ja que ele vai tentar carregar
        // os modulos em comptime
        skip: {
            switch(comptime module.load) {
                .dynamic, .unlinkable => break :skip {},
                .linkable => {
                    @call(.never_inline, module.init, .{}) catch {
                        // klog error
                    };
                },
            }
        }
    }
}
