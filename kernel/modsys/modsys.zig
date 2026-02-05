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
            if(module.flags.call.handler == 1) {
                // resolvendo modulo com base no seu tipo
                switch(comptime module.type) {
                    .driver => {},
                    .syscall => {},
                    .irq => {},
                    .filesystem => {
                        switch(comptime module.type.filesystem) {
                            // caso o modulo fs use compile, vamos fazer uma
                            // montagem do fs em tempo de compilacao
                            .compile => |fs_info| {
                                @call(.never_inline, interfaces.vfs.mount, .{
                                    fs_info.mountpoint, null, fs_info.name
                                }) catch {
                                    // klog()
                                };
                            },
                            .dynamic => break :skip,
                        }
                    },
                }
            }
            if(module.flags.call.after == 1) {
                if(module.after == null) @compileError(
                    "modsys: module " ++ module.name ++
                    " expect call after fn, but after is null in module description"
                );
                @call(.never_inline, module.after.?, .{}) catch {
                    // klog()
                };
            }
        }
    }
}
