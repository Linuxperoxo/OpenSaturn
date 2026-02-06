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
                    @call(.never_inline, interfaces.module.inmod, .{ module.mod }) catch |err| {
                        switch(err) {
                            interfaces.module.ModErr_T.InitFailed => {
                                // klog()
                                interfaces.module.rmmod(module.mod) catch {
                                    // klog()
                                };
                            },

                            interfaces.module.ModErr_T.ModuleCollision => {
                                // klog()
                            },

                            interfaces.module.ModErr_T.ListInitFailed,
                            interfaces.module.ModErr_T.ListOperationError => {
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
