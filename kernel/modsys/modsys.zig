// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modsys.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;
const deps: type = @import("deps.zig");

pub fn saturn_modules_loader() void {
    inline for(comptime deps.resolve_dependencies()) |module| {
        skip: {
            switch(comptime module.load) {
                .dynamic, .unlinkable => break :skip {},
                .linkable => {
                    module.mod.insmod(module.insf) catch |err| {
                        switch(err) {
                            interfaces.module.ModErr_T.InitFailed => {
                                // klog()
                                module.mod.rmmod() catch {
                                    // klog()
                                };
                            },

                            interfaces.module.ModErr_T.ObsoleteDependency,
                            interfaces.module.ModErr_T.OperationFailed => {
                                // klog()
                            },

                            else => unreachable,
                        }
                        if(module.panic) {
                            // panic();
                            //unreachable;
                        }
                    };
                },
            }
        }
    }
}
